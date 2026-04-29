#!/usr/bin/env bash
set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# ───────────────────────────────────────────────
# 1. Validate Arch-based system
# ───────────────────────────────────────────────
if ! command -v pacman &> /dev/null; then
    log_error "This script is designed for Arch-based systems only (pacman not found)."
    exit 1
fi

HOSTNAME=$(hostname)
log_info "Detected hostname: ${HOSTNAME}"

# ───────────────────────────────────────────────
# 2. Install iNiR (one-time, not tracked by dcli)
# ───────────────────────────────────────────────
INIR_TMP="/tmp/inir"
log_info "Cloning and installing iNiR..."
if [ -d "${INIR_TMP}" ]; then
    rm -rf "${INIR_TMP}"
fi
git clone https://github.com/snowarch/inir.git "${INIR_TMP}"
cd "${INIR_TMP}"
./setup install -y
cd /
rm -rf "${INIR_TMP}"
log_info "iNiR installation complete :)."

# ───────────────────────────────────────────────
# 3. Install dcli-arch-git from AUR
# ───────────────────────────────────────────────
log_info "Installing dcli..."
AUR_HELPER=""

if command -v paru &> /dev/null; then
    AUR_HELPER="paru"
    log_info "Found AUR helper: paru"
elif command -v yay &> /dev/null; then
    AUR_HELPER="yay"
    log_info "Found AUR helper: yay"
else
    log_warn "No AUR helper found. Bootstrapping paru..."
    sudo pacman -S --needed --noconfirm base-devel
    PARU_TMP="/tmp/paru"
    rm -rf "${PARU_TMP}"
    git clone https://aur.archlinux.org/paru.git "${PARU_TMP}"
    cd "${PARU_TMP}"
    makepkg -si --noconfirm
    cd /
    rm -rf "${PARU_TMP}"
    AUR_HELPER="paru"
    log_info "paru installed successfully."
fi

${AUR_HELPER} -S --noconfirm dcli-arch-git
log_info "dcli installation complete."

# ───────────────────────────────────────────────
# 4. Initialize dcli configuration (if needed)
# ───────────────────────────────────────────────
DCLI_CONFIG="${HOME}/.config/dcli"
ARCH_CONFIG="${HOME}/.config/arch-config"

# Fallback to legacy arch-config if it exists and dcli dir doesn't
if [ ! -d "${DCLI_CONFIG}" ] && [ -d "${ARCH_CONFIG}" ]; then
    DCLI_CONFIG="${ARCH_CONFIG}"
    log_warn "Using legacy dcli config directory: ${DCLI_CONFIG}"
fi

if [ ! -d "${DCLI_CONFIG}" ]; then
    log_info "Initializing dcli configuration..."
    dcli init
else
    log_info "dcli configuration already exists at ${DCLI_CONFIG}"
fi

# ───────────────────────────────────────────────
# 5. Copy module files into dcli config
# ───────────────────────────────────────────────
REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
log_info "Repo directory:     ${REPO_DIR}"
log_info "dcli config dir:    ${DCLI_CONFIG}"
log_info "Copying inir-dots module to ${DCLI_CONFIG}/modules/..."

# Ensure destinations exist (dcli init usually creates modules/, but be safe)
mkdir -p "${DCLI_CONFIG}/modules"
mkdir -p "${DCLI_CONFIG}/scripts"

# Copy module files
cp -r "${REPO_DIR}/inir-dots" "${DCLI_CONFIG}/modules/"
cp "${REPO_DIR}/scripts/inir-post-install.sh" "${DCLI_CONFIG}/scripts/"
chmod +x "${DCLI_CONFIG}/scripts/inir-post-install.sh"

# Verify the copy worked
if [ ! -f "${DCLI_CONFIG}/modules/inir-dots/module.yaml" ]; then
    log_error "Module copy failed: ${DCLI_CONFIG}/modules/inir-dots/module.yaml not found."
    log_error "Source was: ${REPO_DIR}/inir-dots"
    exit 1
fi
log_info "Module copied successfully."

# ───────────────────────────────────────────────
# 6. Enable the inir-dots module in host config
# ───────────────────────────────────────────────
HOST_FILE="${DCLI_CONFIG}/hosts/${HOSTNAME}.yaml"
if [ ! -f "${HOST_FILE}" ]; then
    log_warn "Host file not found: ${HOST_FILE}"
    log_warn "Skipping automatic module enablement."
    log_warn "To enable manually, add 'inir-dots' to enabled_modules in your host config."
else
    log_info "Adding inir-dots to enabled_modules in ${HOST_FILE}..."
python3 -c "
import sys
path = sys.argv[1]
module = sys.argv[2]

with open(path, 'r') as f:
    lines = f.readlines()

content = ''.join(lines)
if module in content:
    print(f'Module {module} is already enabled in the host config.')
    sys.exit(0)

for i, line in enumerate(lines):
    if line.strip().startswith('enabled_modules:'):
        lines.insert(i + 1, f'  - {module}\n')
        break
else:
    lines.append(f'\nenabled_modules:\n  - {module}\n')

with open(path, 'w') as f:
    f.writelines(lines)
print(f'Module {module} appended to enabled_modules.')
" "${HOST_FILE}" "inir-dots"
fi

# ───────────────────────────────────────────────
# 7. Sync dcli to install all tracked packages
# ───────────────────────────────────────────────
log_info "Running dcli sync to install tracked packages..."
dcli sync

log_info ""
log_info "=========================================="
log_info "Setup complete!"
log_info "=========================================="
log_info "iNiR has been installed and its dependencies"
log_info "are now tracked declaratively by dcli."
log_info ""
log_info "Host config: ${HOST_FILE}"
log_info "Module:      ${DCLI_CONFIG}/modules/inir-dots"
log_info ""
log_info "To re-run the iNiR installer later, use:"
log_info "  dcli hooks run"
log_info ""

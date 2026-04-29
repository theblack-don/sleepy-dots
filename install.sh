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
# 4. Determine dcli config directory
# ───────────────────────────────────────────────
DCLI_CONFIG="${HOME}/.config/dcli"
ARCH_CONFIG="${HOME}/.config/arch-config"

# Fallback to legacy arch-config if it exists and dcli dir doesn't
if [ ! -d "${DCLI_CONFIG}" ] && [ -d "${ARCH_CONFIG}" ]; then
    DCLI_CONFIG="${ARCH_CONFIG}"
    log_warn "Using legacy dcli config directory: ${DCLI_CONFIG}"
fi

# ───────────────────────────────────────────────
# 5. Resolve repo directory (cloned or piped)
# ───────────────────────────────────────────────
# When piped (curl | bash), BASH_SOURCE is empty so we clone the repo.
SCRIPT_SOURCE="${BASH_SOURCE[0]:-}"
if [ -n "${SCRIPT_SOURCE}" ]; then
    REPO_DIR="$(cd "$(dirname "${SCRIPT_SOURCE}")" && pwd)"
else
    log_info "Piped execution detected. Cloning repo to temporary directory..."
    REPO_DIR="/tmp/sleepy-dots"
    rm -rf "${REPO_DIR}"
    git clone https://github.com/theblack-don/sleepy-dots.git "${REPO_DIR}"
fi

TEMPLATE_DIR="${REPO_DIR}/dcli-config"

log_info "Repo directory:  ${REPO_DIR}"
log_info "dcli config dir: ${DCLI_CONFIG}"

if [ ! -d "${TEMPLATE_DIR}" ]; then
    log_error "Template directory not found: ${TEMPLATE_DIR}"
    exit 1
fi

# Backup existing config if present
if [ -d "${DCLI_CONFIG}" ]; then
    BACKUP_DIR="${DCLI_CONFIG}.backup.$(date +%s)"
    log_warn "Existing dcli config found. Backing up to ${BACKUP_DIR}..."
    mv "${DCLI_CONFIG}" "${BACKUP_DIR}"
fi

# Copy template config
log_info "Copying dcli configuration template..."
cp -r "${TEMPLATE_DIR}" "${DCLI_CONFIG}"

# Rename host template to actual hostname
HOST_FILE="${DCLI_CONFIG}/hosts/${HOSTNAME}.yaml"
mv "${DCLI_CONFIG}/hosts/template.yaml" "${HOST_FILE}"

# Update config.yaml to point to the new host file
sed -i "s|hosts/template.yaml|hosts/${HOSTNAME}.yaml|g" "${DCLI_CONFIG}/config.yaml"

log_info "Host config created: ${HOST_FILE}"

# Verify the copy worked
if [ ! -f "${DCLI_CONFIG}/modules/inir-dots/module.yaml" ]; then
    log_error "Module copy failed: ${DCLI_CONFIG}/modules/inir-dots/module.yaml not found."
    exit 1
fi
log_info "Module copied successfully."

# ───────────────────────────────────────────────
# 6. Validate dcli configuration
# ───────────────────────────────────────────────
log_info "Validating dcli configuration..."
set +e
dcli validate
DCLI_VALIDATE_EXIT=$?
set -e
if [ $DCLI_VALIDATE_EXIT -ne 0 ]; then
    log_warn "dcli validate exited with code ${DCLI_VALIDATE_EXIT}."
fi

# ───────────────────────────────────────────────
# 7. Sync dcli to install all tracked packages
# ───────────────────────────────────────────────
log_info "Running dcli sync to install tracked packages..."
set +e
dcli sync
DCLI_SYNC_EXIT=$?
set -e
if [ $DCLI_SYNC_EXIT -ne 0 ]; then
    log_warn "dcli sync exited with code ${DCLI_SYNC_EXIT}."
fi

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

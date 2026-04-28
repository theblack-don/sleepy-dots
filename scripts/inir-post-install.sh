#!/usr/bin/env bash
set -euo pipefail

# Post-install hook for the inir-dots module.
# Re-runs the iNiR setup script so users can refresh or reinstall iNiR
# on a new machine without needing the original install.sh.

TMPDIR="/tmp/inir-dots-reinstall"
echo "[inir-post-install] Cloning iNiR to ${TMPDIR} ..."
rm -rf "${TMPDIR}"
git clone https://github.com/snowarch/inir.git "${TMPDIR}"
cd "${TMPDIR}"

echo "[inir-post-install] Running iNiR setup (auto-accept) ..."
./setup install -y

echo "[inir-post-install] Cleaning up ${TMPDIR} ..."
cd /
rm -rf "${TMPDIR}"

echo "[inir-post-install] Done."

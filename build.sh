#!/usr/bin/env bash
# Build the ISO. Run this ON AN ARCH LINUX HOST, as root, from inside the
# profile directory (the one containing profiledef.sh).
#
#   sudo ./build.sh          # or: su -c ./build.sh
#
# Output lands in ./out/
set -euo pipefail

PROFILE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORK_DIR="${PROFILE_DIR}/work"
OUT_DIR="${PROFILE_DIR}/out"

if [[ $EUID -ne 0 ]]; then
    echo "error: mkarchiso needs root." >&2
    exit 1
fi

if ! command -v mkarchiso >/dev/null 2>&1; then
    echo "error: archiso is not installed. Run: pacman -S archiso" >&2
    exit 1
fi

rm -rf "${WORK_DIR}"
mkdir -p "${OUT_DIR}"

mkarchiso -v -w "${WORK_DIR}" -o "${OUT_DIR}" "${PROFILE_DIR}"

rm -rf "${WORK_DIR}"
echo
echo "Done. ISO is in ${OUT_DIR}/"

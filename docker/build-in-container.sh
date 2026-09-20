#!/usr/bin/env bash
# Runs INSIDE an archlinux container. Builds Calamares from the AUR into a
# local repo, then builds the ISO.
#
# Expects: profile at /profile, output dir at /out.
set -euo pipefail

echo "==> Installing build dependencies"
pacman -Syu --noconfirm --needed archiso base-devel git sudo

echo "==> Creating unprivileged build user (makepkg refuses to run as root)"
if ! id -u builder >/dev/null 2>&1; then
    useradd -m builder
fi
# This sudoers entry exists only inside the throwaway build container.
echo 'builder ALL=(ALL) NOPASSWD: ALL' > /etc/sudoers.d/builder

echo "==> Building Calamares from the AUR"
mkdir -p /repo
chown builder:builder /repo
su - builder -c '
    set -e
    rm -rf ~/build && mkdir -p ~/build && cd ~/build
    git clone --depth 1 https://aur.archlinux.org/calamares.git
    cd calamares
    makepkg -s --noconfirm
    cp calamares-*.pkg.tar.zst /repo/
'
cd /repo
repo-add custom.db.tar.gz calamares-*.pkg.tar.zst

echo "==> Building the ISO"
rm -rf /work
mkdir -p /work /out
mkarchiso -v -w /work -o /out /profile

echo "==> Done"
ls -lh /out

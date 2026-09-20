# Custom Arch Linux KDE ISO — archiso profile

A complete `archiso` profile: KDE Plasma live session, Calamares graphical
installer, and **no sudo configuration** (sudo is installed but no sudoers
drop-in is written and the new user is not put in `wheel`).

Build it on an Arch Linux machine — mkarchiso cannot run anywhere else.

---

> **On Windows?** See `WINDOWS.md` — you do not need an Arch machine, and you
> can skip steps 1 and 2 entirely.

## Step 1 — Build Calamares (it is not in the official repos)

`calamares` lives in the AUR, so it has to be built once and served from a
local repo that `mkarchiso` can read at `file:///repo`.

`docker/build-in-container.sh` does all of this for you — it is the same script
the Docker and GitHub Actions paths use, and it works on a plain Arch host too:

```bash
sudo pacman -S --needed archiso base-devel git
sudo ./docker/build-in-container.sh   # builds Calamares, then the ISO, into /out
```

If you would rather do it by hand:

```bash
mkdir -p /repo && cd ~
git clone https://aur.archlinux.org/calamares.git
cd calamares && makepkg -s          # do NOT run makepkg as root
sudo cp calamares-*.pkg.tar.zst /repo/
cd /repo && sudo repo-add custom.db.tar.gz calamares-*.pkg.tar.zst
```

To serve the repo from somewhere other than `/repo`, change the `Server` line
in the `[custom]` block of `pacman.conf`.

## Step 2 — Build the ISO

```bash
cd /path/to/this/profile
sudo ./build.sh
```

Takes 10–30 minutes and needs roughly 15 GB free. The ISO appears in `out/`.

## Step 3 — Test it

```bash
qemu-system-x86_64 -enable-kvm -m 4096 -smp 4 \
  -bios /usr/share/edk2/x64/OVMF.4m.fd \
  -cdrom out/archlive-kde-*.iso
```

Give it 4 GB of RAM or Plasma will crawl, and attach a spare disk image if you
want to exercise the installer end to end.

---

## How the "no sudo" part works

This is the piece most custom ISOs get wrong, so here is exactly what happens.

**On the installed system:**

- `sudoersGroup` is commented out in `airootfs/etc/calamares/modules/users.conf`.
  When that key is set, Calamares writes `/etc/sudoers.d/10-installer` granting
  the group blanket rights. Unset, it writes nothing at all.
- `wheel` is absent from `defaultGroups` in the same file, so the new user never
  joins it.
- The cleanup shell process deletes `/etc/sudoers.d/10-installer` and
  `/etc/sudoers.d/g_wheel` anyway, in case a future Calamares version changes
  its defaults.
- `sudo` is still in `packages.x86_64`, so the binary is there and you can
  configure it later with `visudo` from a root shell.

Administration is therefore done as root: `su -` in a terminal, using the root
password Calamares asks for during install.

**On the live medium**, the `liveuser` account also has no sudo — which would
normally make it impossible to launch an installer. Instead,
`airootfs/etc/polkit-1/rules.d/49-calamares.rules` authorises that one user to
run `/usr/bin/calamares` via `pkexec`, plus udisks2 actions for mounting. The
desktop launcher calls `pkexec calamares`. That rule is deleted from the target
during install, so it never reaches the finished system.

---

## Layout

```
profiledef.sh                       ISO name, label, compression, boot modes
packages.x86_64                     everything pacstrapped into the live env
pacman.conf                         repos used during the build (+ local AUR repo)
build.sh                            wrapper around mkarchiso
efiboot/                            systemd-boot entries (UEFI)
syslinux/                           syslinux menus (BIOS)
airootfs/                           overlay copied on top of the live root
├── etc/systemd/system/             enabled units, incl. live-setup.service
├── etc/sddm.conf.d/autologin.conf  autologin liveuser into Plasma
├── etc/polkit-1/rules.d/           the installer authorisation rule
├── etc/skel/Desktop/               "Install Custom Arch Linux" launcher
├── usr/local/bin/live-setup        creates liveuser at boot (no wheel)
└── etc/calamares/                  installer config
    ├── settings.conf               module sequence
    ├── modules/*.conf              per-module settings
    └── branding/custom/            logo, colours, slideshow
```

## Common customisations

| Want to… | Edit |
|---|---|
| Add/remove software | `packages.x86_64` |
| Rename the ISO / distro | `profiledef.sh` and `branding/custom/branding.desc` |
| Change the live user's name | `usr/local/bin/live-setup`, `sddm.conf.d/autologin.conf`, `polkit-1/rules.d/49-calamares.rules`, `modules/removeuser.conf` — all four must match |
| Swap Plasma for something else | `packages.x86_64`, `modules/displaymanager.conf`, `sddm.conf.d/autologin.conf` |
| Re-enable normal sudo | uncomment `sudoersGroup: wheel` in `modules/users.conf`, add `wheel` to `defaultGroups`, drop the two `rm -f /etc/sudoers.d/...` lines from `modules/shellprocess_cleanup.conf` |
| Real branding art | replace `branding/custom/logo.png` (256×256) and `welcome.png` (640×360) |

## Gotchas

- Plasma refuses to run a session as root, which is why `liveuser` exists.
- If Calamares starts but the disk step is empty, `kpmcore` is missing or its
  version does not match the Calamares build — rebuild the AUR package.
- If `unpackfs` fails, check the squashfs path in `modules/unpackfs.conf`
  against `install_dir` in `profiledef.sh`; they must agree.
- `mkarchiso` needs a filesystem that supports extended attributes for `work/`.
  Building on tmpfs or an exFAT/NTFS mount will fail.

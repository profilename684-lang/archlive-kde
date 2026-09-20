# Building this ISO from Windows

`mkarchiso` is an Arch Linux tool, so it needs an Arch userland somewhere.
Pick one of these. Option A needs nothing installed locally.

---

## A. GitHub Actions — recommended, zero local setup

Push this profile to a GitHub repo. `.github/workflows/build-iso.yml` builds
the ISO in an Arch container on GitHub's runners and hands you the file as a
downloadable artifact.

```powershell
cd path\to\archlive
git init
git add .
git commit -m "custom arch iso profile"
git branch -M main
git remote add origin https://github.com/YOURNAME/YOURREPO.git
git push -u origin main
```

Then open the repo's **Actions** tab, watch the run (20–40 min), and download
the artifact from the run summary when it finishes.

Notes:

- The workflow deletes the runner's preinstalled .NET/Android SDKs first,
  because a KDE ISO needs more disk than the runner ships with free.
- Artifacts expire after 7 days — change `retention-days` if you want longer,
  or publish to a Release instead for a permanent URL.
- Re-run any time from **Actions → Build ISO → Run workflow**.

## B. Docker Desktop — build locally

Requires Docker Desktop with the WSL2 backend, and about 20 GB free.

```powershell
powershell -ExecutionPolicy Bypass -File .\build-docker.ps1
```

The script copies the profile into the container's own filesystem before
building. **This part matters:** `mkarchiso` sets extended attributes and
device nodes, which a Windows bind mount (NTFS via 9p/virtiofs) cannot store.
Building directly on `C:\` fails partway with permission or xattr errors. Only
the finished ISO is copied back to `.\out\`.

The container runs `--privileged` because the build needs loop devices to
assemble the EFI system partition image.

## C. WSL2 with ArchWSL — also works

```powershell
winget install --id 9MZNMNKSM73X   # ArchWSL from the Store, or use yuk7/ArchWSL
```

Inside the Arch WSL shell:

```bash
sudo pacman -Syu --needed archiso base-devel git
cd ~                      # NOT /mnt/c — see the xattr warning above
cp -r /mnt/c/path/to/archlive .
cd archlive
sudo ./docker/build-in-container.sh   # works fine outside a container too
```

Copy the ISO out at the end: `cp out/*.iso /mnt/c/Users/you/Desktop/`

Caveat: older WSL2 kernels lack loop-device support and the ESP step fails.
Run `wsl --update` first if you hit that.

## D. A real Arch VM

VirtualBox, VMware Workstation Player or Hyper-V, install Arch, then follow the
main `README.md`. Slowest to set up, fewest surprises.

---

## Then: writing the ISO to a USB stick

Windows has no `dd`. Use one of:

- **Rufus** — pick the ISO, leave everything default, choose **DD Image mode**
  when it asks. ISO mode mangles archiso's hybrid boot layout on some sticks.
- **Ventoy** — install once to the stick, then just copy `.iso` files onto it.
  Best option if you plan to iterate on this ISO more than once.
- **balenaEtcher** — simplest, no options to get wrong.

## Testing without a USB stick

Boot the ISO in a VM before trusting it to hardware. Hyper-V needs a
**Generation 2** VM with Secure Boot **disabled**. VirtualBox needs
**Settings → System → Enable EFI** to test the UEFI path, and at least 4 GB of
RAM or Plasma will be unusable.

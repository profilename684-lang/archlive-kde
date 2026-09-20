# Build the ISO on Windows using Docker Desktop (WSL2 backend required).
#
#   powershell -ExecutionPolicy Bypass -File .\build-docker.ps1
#
# The finished ISO lands in .\out\

$ErrorActionPreference = "Stop"

$profileDir = $PSScriptRoot
$outDir     = Join-Path $profileDir "out"

if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
    Write-Error "Docker Desktop is not installed or not on PATH."
}

New-Item -ItemType Directory -Force -Path $outDir | Out-Null

Write-Host "Building. This takes 20-40 minutes and needs ~20 GB free." -ForegroundColor Cyan

# The profile is copied to the container's own filesystem first: mkarchiso
# needs extended attributes, which a Windows bind mount cannot provide.
# Only the finished ISO is written back out to the mounted folder.
docker run --privileged --rm `
    -v "${profileDir}:/profile-src:ro" `
    -v "${outDir}:/out" `
    archlinux:latest `
    bash -c "cp -a /profile-src /profile && /profile/docker/build-in-container.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Error "Build failed with exit code $LASTEXITCODE"
}

Write-Host "`nDone. ISO is in $outDir" -ForegroundColor Green
Get-ChildItem $outDir

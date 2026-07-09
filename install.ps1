# Install TVMonkey on Windows.
#
# Usage:
#   pwsh scripts/install.ps1            # install for current user (no admin)
#   pwsh scripts/install.ps1 -System    # install to C:\Program Files\tvmonkey (needs admin)
#
# Requires Bun (https://bun.sh) and npm. Run from a PowerShell terminal.

[CmdletBinding()]
param(
  [switch]$System
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
$binName = 'tvmonkey.exe'

if ($System) {
  $prefix = 'C:\Program Files\tvmonkey'
} else {
  $prefix = Join-Path $env:LOCALAPPDATA 'Programs\tvmonkey'
}

Write-Host "[tvmonkey-install] repo: $repoRoot"
Write-Host "[tvmonkey-install] install prefix: $prefix"

# --- prerequisites ---
$bun = Get-Command bun -ErrorAction SilentlyContinue
if (-not $bun) {
  Write-Host '[tvmonkey-install] ERROR: Bun is required to build the binary.' -ForegroundColor Red
  Write-Host '[tvmonkey-install] Install from https://bun.sh then re-run.' -ForegroundColor Red
  exit 1
}

$npm = Get-Command npm -ErrorAction SilentlyContinue
if (-not $npm) {
  Write-Host '[tvmonkey-install] ERROR: npm is required to install dependencies.' -ForegroundColor Red
  exit 1
}

Write-Host "[tvmonkey-install] Bun: $(bun --version)"
Write-Host "[tvmonkey-install] npm: $(npm --version)"

# --- build ---
Set-Location $repoRoot
if (-not (Test-Path 'node_modules')) {
  Write-Host '[tvmonkey-install] installing npm dependencies...'
  npm install
}

Write-Host '[tvmonkey-install] building binary...'
npm run build

# Bun compile output is dist/tvmonkey (no .exe extension on the compile target).
# The compiled binary is a real native executable; rename to .exe on Windows.
$built = Join-Path $repoRoot 'dist\tvmonkey'
if (-not (Test-Path $built)) {
  Write-Host '[tvmonkey-install] ERROR: build did not produce dist\tvmonkey' -ForegroundColor Red
  exit 1
}

# --- install binary ---
if (-not (Test-Path $prefix)) {
  New-Item -ItemType Directory -Path $prefix -Force | Out-Null
}
if ($System) {
  $dest = Join-Path $prefix $binName
  Copy-Item $built $dest -Force
} else {
  $dest = Join-Path $prefix $binName
  Copy-Item $built $dest -Force
}

# --- config directory (private, per-user) ---
$configDir = Join-Path $env:APPDATA 'tvmonkey'
if (-not (Test-Path $configDir)) {
  New-Item -ItemType Directory -Path $configDir -Force | Out-Null
}
# On Windows the env file sits in %APPDATA%\tvmonkey\env; the folder ACL inherits
# per-user isolation from %APPDATA%, which is the Windows equivalent of 0700.
Write-Host "[tvmonkey-install] config dir: $configDir"

# --- verify / add PATH (user-level only) ---
$inPath = ($env:Path -split ';') -contains $prefix
if (-not $inPath) {
  if ($System) {
    Write-Host '[tvmonkey-install] NOTE: add to system PATH manually:' -ForegroundColor Yellow
    Write-Host "    $prefix"
  } else {
    $userPath = [Environment]::GetEnvironmentVariable('Path', 'User')
    if (-not $userPath) { $userPath = '' }
    if ($userPath -notlike "*$prefix*") {
      $newUserPath = if ($userPath) { "$userPath;$prefix" } else { $prefix }
      [Environment]::SetEnvironmentVariable('Path', $newUserPath, 'User')
      Write-Host "[tvmonkey-install] added $prefix to user PATH (takes effect in new terminals)."
    }
    $env:Path += ";$prefix"
  }
}

# --- success ---
Write-Host ''
Write-Host '[tvmonkey-install] DONE — installed ' -NoNewline
Write-Host "$dest" -ForegroundColor Green
& $dest --version | ForEach-Object { Write-Host "[tvmonkey-install] Version: $_" }
Write-Host ''
Write-Host 'Next steps:'
Write-Host '  1. Open a new terminal so PATH updates take effect (if not using -System).'
Write-Host '  2. Run: tvmonkey'
Write-Host '  3. The TUI config panel opens on first run — fill NGQ_API_KEY and save.'
Write-Host ''
Write-Host 'To run bridge as a background service:'
Write-Host '  tvmonkey --bridge'
Write-Host 'Service examples (launchd/systemd/Task Scheduler/NSSM) are in INSTALL.md.'
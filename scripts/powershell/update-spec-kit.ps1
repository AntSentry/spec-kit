#!/usr/bin/env pwsh
param()
$ErrorActionPreference = 'Stop'

function Require($name) {
  if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
    Write-Error "Missing dependency: $name"; exit 1
  }
}
Require git

$root = (git rev-parse --show-toplevel) 2>$null
if (-not $root) { Write-Error 'Must run inside a git repo'; exit 1 }
Set-Location $root

Write-Host '=== Spec Kit Updater (PowerShell) ==='

function Ensure-Remote($name, $url) {
  try { git remote get-url $name *> $null; return } catch {}
  git remote add $name $url *> $null
}

Write-Host 'Checking remotes...'
Ensure-Remote origin 'https://github.com/AntSentry/spec-kit.git'
Ensure-Remote upstream 'https://github.com/github/spec-kit.git'

Write-Host 'Fetching remotes...'
git fetch origin --tags
git fetch upstream --tags

$hasChanges = $false
if ((git diff --quiet; $LASTEXITCODE) -ne 0 -or (git diff --cached --quiet; $LASTEXITCODE) -ne 0) { $hasChanges = $true }
if ($hasChanges) {
  Write-Host 'Working tree has local changes. Stashing...'
  git stash push -u -m ("pre-update-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
  $stashed = $true
} else { $stashed = $false }

Write-Host 'Switching to main and rebasing onto upstream/main...'
git checkout main
git fetch upstream main
git rebase upstream/main

Write-Host 'Pushing updated main to origin...'
git push origin main

if ($stashed) {
  Write-Host 'Re-applying stashed changes (if conflict-free)...'
  $stash = (git stash list | Select-String pre-update- | Select-Object -First 1)
  if ($stash) { git stash pop }
}

Write-Host 'Running compatibility checks...'
try {
  python -m compileall "$root/src/specify_cli" *> $null
  $pyOk = $true
} catch { $pyOk = $false }

$missing = @()
if (-not (Test-Path "$root/.github/workflows/scripts/create-release-packages.sh")) { $missing += 'packaging_script' }
if (-not (Test-Path "$root/scripts/bash/sync-codex-prompts.sh")) { $missing += 'codex_sync_sh' }
if (-not (Test-Path "$root/scripts/powershell/sync-codex-prompts.ps1")) { $missing += 'codex_sync_ps1' }
if (-not (Test-Path "$root/templates/commands/codex")) { $missing += 'codex_templates' }

Write-Host '--- Update Report ---'
Write-Host ("root: " + $root)
Write-Host ("branch: " + (git rev-parse --abbrev-ref HEAD))
Write-Host ("upstream HEAD: " + (git rev-parse upstream/main))
Write-Host ("local HEAD: " + (git rev-parse HEAD))
Write-Host ("cli_compile: " + (if ($pyOk) { 'ok' } else { 'fail' }))
if ($missing.Count -gt 0) {
  Write-Error ("missing: " + ($missing -join ' '))
  exit 3
}
Write-Host 'status: updated'


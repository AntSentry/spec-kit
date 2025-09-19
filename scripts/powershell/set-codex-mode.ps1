#!/usr/bin/env pwsh
param([Parameter(Mandatory=$true)][string]$Mode)
$ErrorActionPreference = 'Stop'

$root = (git rev-parse --show-toplevel) 2>$null
if (-not $root) { $root = (Get-Location).Path }
$cfg = Join-Path $root '.specify/codex.json'
New-Item -ItemType Directory -Force -Path (Split-Path $cfg) | Out-Null

if (Test-Path $cfg) {
  try { $json = Get-Content $cfg -Raw | ConvertFrom-Json } catch { $json = @{} }
  $json.mode = $Mode
  $json | ConvertTo-Json -Depth 5 | Set-Content $cfg -Encoding UTF8
  Write-Host "Set Codex mode: $Mode"
} else {
  "{`n  \"mode\": \"$Mode\"`n}" | Set-Content $cfg -Encoding UTF8
  Write-Host "Set Codex mode: $Mode"
}


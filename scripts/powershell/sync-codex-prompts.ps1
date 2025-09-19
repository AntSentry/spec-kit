#!/usr/bin/env pwsh
param()

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
if ($ScriptDir -match '\\.specify') {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptDir '../../..')
} else {
    $ProjectRoot = Resolve-Path (Join-Path $ScriptDir '../..')
}

$SourceDir = Join-Path $ProjectRoot '.codex/prompts'
if (-not (Test-Path $SourceDir)) {
    Write-Error "Codex prompts not found at $SourceDir"
    exit 1
}

$CodexHome = if ($env:CODEX_HOME) { $env:CODEX_HOME } else { Join-Path $HOME '.codex' }
$TargetDir = Join-Path $CodexHome 'prompts'
New-Item -ItemType Directory -Force -Path $TargetDir | Out-Null

$Timestamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$BackupDir = Join-Path $TargetDir (".backup-spec-kit-$Timestamp")
New-Item -ItemType Directory -Force -Path $BackupDir | Out-Null

$PromptFiles = Get-ChildItem -Path $SourceDir -Filter '*.md' -ErrorAction SilentlyContinue
if (-not $PromptFiles) {
    Write-Error "No Codex prompts found under $SourceDir"
    exit 1
}

foreach ($file in $PromptFiles) {
    $Destination = Join-Path $TargetDir $file.Name
    if (Test-Path $Destination) {
        Move-Item -Path $Destination -Destination (Join-Path $BackupDir $file.Name) -Force
    }
    Copy-Item -Path $file.FullName -Destination $Destination -Force
    Write-Host "Installed $Destination"
}

Write-Host "`nCodex prompts synchronized."
Write-Host "- Source: $SourceDir"
Write-Host "- Target: $TargetDir"
Write-Host "- Backup: $BackupDir"
Write-Host "`nRestart your Codex session to pick up the new slash commands."

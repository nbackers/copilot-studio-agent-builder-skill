<#
.SYNOPSIS
    Validates and packages Copilot Studio skills for upload.

.DESCRIPTION
    Checks each skill folder against the rules that cause upload failures, then produces
    a zip with SKILL.md at the archive root.

    Validated:
      - SKILL.md present
      - YAML front matter present and parseable
      - name is lowercase kebab case
      - name matches the folder name
      - description present and long enough to route on
      - file is UTF-8 without BOM
      - SKILL.md lands at the archive root

.PARAMETER Path
    Folder containing skill subfolders. Defaults to the repo's skills folder.

.PARAMETER Name
    Package a single named skill instead of all of them.

.PARAMETER ValidateOnly
    Run the checks without producing archives.

.EXAMPLE
    .\Build-SkillPackage.ps1

.EXAMPLE
    .\Build-SkillPackage.ps1 -ValidateOnly

.EXAMPLE
    .\Build-SkillPackage.ps1 -Name build-copilot-agent
#>
[CmdletBinding()]
param(
    [string] $Path = (Join-Path $PSScriptRoot '..\skills'),
    [string] $Name,
    [switch] $ValidateOnly
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Path = (Resolve-Path -LiteralPath $Path).Path

$dirs = Get-ChildItem -LiteralPath $Path -Directory
if ($Name) { $dirs = $dirs | Where-Object { $_.Name -eq $Name } }
if (-not $dirs) { throw "No skill folders found in $Path" }

$failures = 0
$packaged = 0

foreach ($dir in $dirs) {

    Write-Host ''
    Write-Host $dir.Name -ForegroundColor Cyan

    $skillFile = Join-Path $dir.FullName 'SKILL.md'
    $errors = @()
    $warnings = @()

    if (-not (Test-Path -LiteralPath $skillFile)) {
        Write-Host '  FAIL  no SKILL.md' -ForegroundColor Red
        $failures++
        continue
    }

    # A UTF-8 BOM breaks front matter parsing on upload.
    $bytes = [System.IO.File]::ReadAllBytes($skillFile)
    if ($bytes.Length -ge 3 -and $bytes[0] -eq 0xEF -and $bytes[1] -eq 0xBB -and $bytes[2] -eq 0xBF) {
        $errors += 'SKILL.md has a UTF-8 BOM - front matter will not parse'
    }

    $content = [System.IO.File]::ReadAllText($skillFile)

    $fm = [regex]::Match($content, '(?s)^---\r?\n(.*?)\r?\n---')
    if (-not $fm.Success) {
        $errors += 'no YAML front matter delimited by --- at the top of the file'
    }
    else {
        $block = $fm.Groups[1].Value

        $nameMatch = [regex]::Match($block, '(?m)^name:\s*(.+?)\s*$')
        if (-not $nameMatch.Success) {
            $errors += 'front matter has no name'
        }
        else {
            $skillName = $nameMatch.Groups[1].Value.Trim()

            if ($skillName -cnotmatch '^[a-z0-9]+(-[a-z0-9]+)*$') {
                $errors += "name '$skillName' must be lowercase letters, numbers and hyphens only"
            }
            if ($skillName -ne $dir.Name) {
                $errors += "name '$skillName' does not match folder name '$($dir.Name)'"
            }
        }

        $descMatch = [regex]::Match($block, '(?ms)^description:\s*(.+?)(?=^\w+:|\z)')
        if (-not $descMatch.Success) {
            $errors += 'front matter has no description'
        }
        else {
            $desc = $descMatch.Groups[1].Value.Trim()
            if ($desc.Length -lt 60) {
                $warnings += "description is only $($desc.Length) chars - too vague to route on reliably"
            }
            if ($desc -notmatch '(?i)do not use|not for') {
                $warnings += 'description has no negative scope ("Do not use for...") - may overlap with siblings'
            }
        }
    }

    foreach ($e in $errors) { Write-Host "  FAIL  $e" -ForegroundColor Red }
    foreach ($w in $warnings) { Write-Host "  WARN  $w" -ForegroundColor Yellow }

    if ($errors.Count -gt 0) {
        $failures++
        continue
    }

    if (-not $warnings) { Write-Host '  OK    validation passed' -ForegroundColor Green }

    if ($ValidateOnly) { continue }

    $zip = Join-Path $Path "$($dir.Name).zip"
    if (Test-Path -LiteralPath $zip) { Remove-Item -LiteralPath $zip -Force }

    # Wildcard on the folder contents keeps SKILL.md at the archive root.
    Compress-Archive -Path (Join-Path $dir.FullName '*') -DestinationPath $zip -Force

    Add-Type -AssemblyName System.IO.Compression.FileSystem
    $archive = [IO.Compression.ZipFile]::OpenRead($zip)
    try {
        $entries = @($archive.Entries | ForEach-Object { $_.FullName })
    }
    finally {
        $archive.Dispose()
    }

    if ($entries -notcontains 'SKILL.md') {
        Write-Host "  FAIL  SKILL.md is not at the archive root (found: $($entries -join ', '))" -ForegroundColor Red
        $failures++
        continue
    }

    Write-Host "  OK    packaged $($dir.Name).zip" -ForegroundColor Green
    $packaged++
}

Write-Host ''
if ($failures -gt 0) {
    Write-Host "$failures skill(s) failed validation." -ForegroundColor Red
    Write-Host ''
    exit 1
}

if ($ValidateOnly) {
    Write-Host 'All skills passed validation.' -ForegroundColor Green
}
else {
    Write-Host "$packaged skill(s) packaged. Upload via Copilot Studio > Build > Skills > Add skill." -ForegroundColor Green
}
Write-Host ''
exit 0

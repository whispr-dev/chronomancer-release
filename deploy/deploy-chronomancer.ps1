#Requires -Version 5.1
<#
.SYNOPSIS
  Publishes the Chronomancer download page to https://whispr.dev/chronomancer/

.DESCRIPTION
  1. Reads the built MSI + portable zip from ..\dist (run installer\build.ps1 first).
  2. Fills the page template with version, sizes and SHA-256 checksums.
  3. Uploads everything to sgp1 with scp, then runs install-on-server.sh there
     (it backs up any existing /chronomancer/ and swaps the new one in).

  Uses your existing SSH alias:  ssh sgp1

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\deploy-chronomancer.ps1
#>
[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+\.\d+$')]
    [string]$Version = '8.2.0.0',
    [string]$DistDir = '',
    [string]$PayloadDir = '',
    [string]$SiteDir = '',
    [string]$SshHost = 'sgp1',
    [string]$WebRoot = '/srv/whispr-static/whispr.dev',
    [string]$SiteUrl = 'https://whispr.dev'
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Work out where this script lives. ($PSScriptRoot can be blank inside param() on Windows PowerShell 5.1.)
$Here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $DistDir) { $DistDir = Join-Path $Here '..\dist' }
if (-not $PayloadDir) { $PayloadDir = Join-Path $Here '..\payload' }
if (-not $SiteDir) { $SiteDir = Join-Path $Here '..\site\chronomancer' }

function Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Size([long]$bytes) { '{0:N1} MB' -f ($bytes / 1MB) }
function Sha([string]$path) { (Get-FileHash $path -Algorithm SHA256).Hash.ToLower() }
function Invoke-Native([string]$exe, [string[]]$argv) {
    & $exe @argv
    if ($LASTEXITCODE -ne 0) { throw "$exe $($argv -join ' ') failed (exit $LASTEXITCODE)." }
}

# ---------- 1. Inputs ----------
Step 'Checking inputs'
foreach ($tool in 'ssh', 'scp') {
    if (-not (Get-Command $tool -ErrorAction SilentlyContinue)) {
        throw "$tool not found. Turn on Windows' OpenSSH Client: Settings > System > Optional features > View features > OpenSSH Client."
    }
}
$msiName = "Chronomancer-$Version.msi"
$zipName = "whispr.dev-Chronomancer-$Version-portable.zip"
$msi = Join-Path $DistDir $msiName
$zip = Join-Path $DistDir $zipName
foreach ($f in $msi, $zip,
               (Join-Path $SiteDir 'index.html'),
               (Join-Path $SiteDir 'chronomancer-icon.png'),
               (Join-Path $SiteDir 'favicon-64.png'),
               (Join-Path $PayloadDir 'README.md'),
               (Join-Path $PayloadDir 'LICENSE.txt'),
               (Join-Path $Here 'install-on-server.sh')) {
    if (-not (Test-Path $f)) { throw "Missing: $f  (did you run installer\build.ps1 -Version $Version ?)" }
}

# ---------- 2. Render page ----------
Step 'Rendering page'
$tokens = [ordered]@{
    '{{VERSION}}'      = $Version
    '{{RELEASE_DATE}}' = (Get-Date).ToString('d MMMM yyyy', [Globalization.CultureInfo]::GetCultureInfo('en-GB'))
    '{{MSI_FILE}}'     = $msiName
    '{{MSI_SIZE}}'     = Size (Get-Item $msi).Length
    '{{MSI_SHA256}}'   = Sha $msi
    '{{ZIP_FILE}}'     = $zipName
    '{{ZIP_SIZE}}'     = Size (Get-Item $zip).Length
    '{{ZIP_SHA256}}'   = Sha $zip
}
$html = [IO.File]::ReadAllText((Join-Path $SiteDir 'index.html'))
foreach ($k in $tokens.Keys) { $html = $html.Replace($k, [string]$tokens[$k]) }
if ($html -match '\{\{[A-Z0-9_]+\}\}') { throw "Unfilled template token left in page: $($Matches[0])" }

$stageRoot = Join-Path $env:TEMP ("chronomancer-deploy-" + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$stage = Join-Path $stageRoot 'chronomancer'
$dl = Join-Path $stage 'download'
New-Item -ItemType Directory -Force -Path $dl | Out-Null

$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $stage 'index.html'), $html, $utf8NoBom)
Copy-Item (Join-Path $SiteDir 'chronomancer-icon.png') $stage
Copy-Item (Join-Path $SiteDir 'favicon-64.png') $stage
Copy-Item $msi, $zip $dl
Copy-Item (Join-Path $PayloadDir 'LICENSE.txt') $dl
Copy-Item (Join-Path $PayloadDir 'README.md') (Join-Path $dl 'README.txt')
$sums = "$($tokens['{{MSI_SHA256}}'])  $msiName`n$($tokens['{{ZIP_SHA256}}'])  $zipName`n"
[IO.File]::WriteAllText((Join-Path $dl 'SHA256SUMS.txt'), $sums, $utf8NoBom)

# server script with guaranteed LF line endings
$sh = [IO.File]::ReadAllText((Join-Path $Here 'install-on-server.sh')).Replace("`r`n", "`n")
[IO.File]::WriteAllText((Join-Path $stageRoot 'install.sh'), $sh, $utf8NoBom)

Write-Host "Staged at $stageRoot"
$tokens.GetEnumerator() | ForEach-Object { Write-Host ("  {0,-16} {1}" -f $_.Key.Trim('{}'), $_.Value) }

# ---------- 3. Upload ----------
Step "Uploading to $SshHost"
Invoke-Native 'ssh' @($SshHost, 'rm -rf ~/chronomancer-staging && mkdir -p ~/chronomancer-staging')
Invoke-Native 'scp' @('-r', $stage, (Join-Path $stageRoot 'install.sh'), "${SshHost}:chronomancer-staging/")

# ---------- 4. Install on server ----------
Step 'Swapping into the live site'
Invoke-Native 'ssh' @('-t', $SshHost, "bash ~/chronomancer-staging/install.sh '$WebRoot' '$SiteUrl'")

# ---------- 5. Check from here ----------
Step 'Checking from this PC'
foreach ($url in "$SiteUrl/chronomancer/", "$SiteUrl/chronomancer/download/$msiName") {
    try {
        $r = Invoke-WebRequest -Uri $url -Method Head -UseBasicParsing
        Write-Host ("  {0}  {1}" -f $r.StatusCode, $url)
    }
    catch {
        Write-Warning "  $url -> $($_.Exception.Message)"
    }
}

Remove-Item $stageRoot -Recurse -Force
Write-Host "`nLive: $SiteUrl/chronomancer/" -ForegroundColor Green

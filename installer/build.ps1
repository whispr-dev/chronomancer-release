#Requires -Version 5.1
<#
.SYNOPSIS
  Builds the Chronomancer MSI and the portable zip, then writes SHA-256 checksums.

.DESCRIPTION
  Output goes to ..\dist\ :
    Chronomancer-<Version>.msi
    whispr.dev-Chronomancer-<Version>-portable.zip
    SHA256SUMS.txt

  Needs the .NET SDK (8 or newer). Installs/pins the WiX command-line tool 6.0.2
  and its UI + Util extensions on first run.

.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\build.ps1
.EXAMPLE
  powershell -ExecutionPolicy Bypass -File .\build.ps1 -Version 8.2.1.0
#>
[CmdletBinding()]
param(
    [ValidatePattern('^\d+\.\d+\.\d+\.\d+$')]
    [string]$Version = '8.2.0.0',
    [string]$PayloadDir = '',
    [string]$OutDir = ''
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

# Work out where this script lives. ($PSScriptRoot can be blank inside param() on Windows PowerShell 5.1.)
$Here = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
if (-not $PayloadDir) { $PayloadDir = Join-Path $Here '..\payload' }
if (-not $OutDir) { $OutDir = Join-Path $Here '..\dist' }

$WixVersion = '6.0.2'
$Extensions = @('WixToolset.UI.wixext', 'WixToolset.Util.wixext')

function Step([string]$msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }

# ---------- 1. Version sanity (MSI limits: 255.255.65535; only first 3 fields count) ----------
$parts = $Version.Split('.') | ForEach-Object { [int]$_ }
if ($parts[0] -gt 255 -or $parts[1] -gt 255 -or $parts[2] -gt 65535) {
    throw "Version $Version is out of MSI range (max 255.255.65535.x)."
}

# ---------- 2. Payload present? ----------
Step 'Checking payload'
$PayloadDir = (Resolve-Path $PayloadDir).Path
$required = 'Chronomancer.exe', 'Chronomancer-Wallpaper.png', 'Chronomancer.ico', 'README.md', 'LICENSE.txt'
foreach ($f in $required) {
    if (-not (Test-Path (Join-Path $PayloadDir $f))) { throw "Missing payload file: $PayloadDir\$f" }
}
$exeVer = (Get-Item (Join-Path $PayloadDir 'Chronomancer.exe')).VersionInfo.FileVersion
if ($exeVer -ne $Version) {
    Write-Warning "Chronomancer.exe reports FileVersion '$exeVer' but you're packaging '$Version'. Make sure this is the right exe."
}

# ---------- 3. .NET SDK ----------
Step 'Checking .NET SDK'
if (-not (Get-Command dotnet -ErrorAction SilentlyContinue)) {
    throw "The .NET SDK isn't installed. Run:  winget install --id Microsoft.DotNet.SDK.8 -e   then open a NEW PowerShell window and run this script again."
}
$sdks = & dotnet --list-sdks
if (-not $sdks) {
    throw "dotnet is present but no SDK is installed (runtime only). Run:  winget install --id Microsoft.DotNet.SDK.8 -e"
}

# ---------- 3b. NuGet source (where dotnet and WiX download packages from) ----------
Step 'Checking the nuget.org package source'
$NuGetUrl = 'https://api.nuget.org/v3/index.json'
$srcList = (& dotnet nuget list source) -join "`n"
if ($srcList -notmatch [regex]::Escape($NuGetUrl)) {
    Write-Host 'nuget.org is not registered - adding it to your NuGet config.'
    & dotnet nuget add source $NuGetUrl --name nuget.org
    if ($LASTEXITCODE -ne 0) {
        # a source already uses the name "nuget.org" but points elsewhere; add ours under another name
        & dotnet nuget add source $NuGetUrl --name nuget.org-v3
        if ($LASTEXITCODE -ne 0) { throw "Couldn't add $NuGetUrl as a NuGet source." }
    }
}
else {
    # registered: make sure whichever entry points at it is enabled
    $lines = $srcList -split "`n"
    for ($i = 1; $i -lt $lines.Count; $i++) {
        if ($lines[$i] -match [regex]::Escape($NuGetUrl) -and $lines[$i - 1] -match '^\s*\d+\.\s+(.+?)\s+\[(Enabled|Disabled)\]') {
            if ($Matches[2] -eq 'Disabled') {
                $srcName = $Matches[1]
                Write-Host "NuGet source '$srcName' is disabled - enabling it."
                & dotnet nuget enable source $srcName
                if ($LASTEXITCODE -ne 0) { throw "Couldn't enable NuGet source '$srcName'." }
            }
        }
    }
}

# ---------- 4. WiX tool, pinned ----------
Step "Ensuring WiX $WixVersion"
$wix = Join-Path $env:USERPROFILE '.dotnet\tools\wix.exe'
$installed = $null
if (Test-Path $wix) {
    $installed = ((& $wix --version) -split '\+')[0].Trim()
}
if ($installed -ne $WixVersion) {
    if ($installed) {
        Write-Host "Found WiX $installed - replacing with $WixVersion"
        & dotnet tool uninstall --global wix | Out-Null
    }
    & dotnet tool install --global wix --version $WixVersion --add-source $NuGetUrl
    if ($LASTEXITCODE -ne 0) { throw 'dotnet tool install wix failed - see the message just above this line.' }
}
Write-Host "WiX: $((& $wix --version))"

# ---------- 5. Extensions, pinned ----------
$extList = (& $wix extension list --global) -join "`n"
foreach ($ext in $Extensions) {
    if ($extList -notmatch [regex]::Escape("$ext $WixVersion")) {
        & $wix extension add --global "$ext/$WixVersion"
    }
}
$extList = (& $wix extension list --global) -join "`n"
foreach ($ext in $Extensions) {
    if ($extList -notmatch [regex]::Escape("$ext $WixVersion")) {
        throw "WiX extension $ext $WixVersion isn't in the global cache. Try:  wix extension add --global $ext/$WixVersion"
    }
}

# ---------- 6. Build MSI ----------
Step "Building MSI $Version"
New-Item -ItemType Directory -Force -Path $OutDir | Out-Null
$OutDir = (Resolve-Path $OutDir).Path
$msi = Join-Path $OutDir "Chronomancer-$Version.msi"
if (Test-Path $msi) { Remove-Item $msi -Force }

Push-Location $Here
try {
    $wixArgs = @(
        'build', (Join-Path $Here 'Chronomancer.wxs'),
        '-arch', 'x64',
        '-culture', 'en-US',
        '-d', "ProductVersion=$Version",
        '-d', "PayloadDir=$PayloadDir",
        '-bindpath', $Here,
        '-o', $msi
    )
    foreach ($ext in $Extensions) { $wixArgs += @('-ext', $ext) }
    & $wix @wixArgs
    if ($LASTEXITCODE -ne 0) { throw "wix build failed (exit $LASTEXITCODE)." }
}
finally {
    Pop-Location
}
# wix also drops a .wixpdb (debug symbols) next to the MSI; keep it out of the release folder
Get-ChildItem $OutDir -Filter '*.wixpdb' | Remove-Item -Force

# ---------- 7. Portable zip ----------
Step 'Building portable zip'
$zip = Join-Path $OutDir "whispr.dev-Chronomancer-$Version-portable.zip"
if (Test-Path $zip) { Remove-Item $zip -Force }
$zipItems = 'Chronomancer.exe', 'Chronomancer-Wallpaper.png', 'README.md', 'LICENSE.txt' |
    ForEach-Object { Join-Path $PayloadDir $_ }
Compress-Archive -Path $zipItems -DestinationPath $zip -CompressionLevel Optimal

# ---------- 8. Checksums ----------
Step 'Writing SHA256SUMS.txt'
$sums = foreach ($f in @($msi, $zip)) {
    $h = (Get-FileHash $f -Algorithm SHA256).Hash.ToLower()
    "$h  $(Split-Path $f -Leaf)"
}
$utf8NoBom = New-Object System.Text.UTF8Encoding $false
[IO.File]::WriteAllText((Join-Path $OutDir 'SHA256SUMS.txt'), (($sums -join "`n") + "`n"), $utf8NoBom)

Step 'Done'
Get-ChildItem $OutDir | Format-Table Name, @{n = 'MB'; e = { '{0:N1}' -f ($_.Length / 1MB) } } -AutoSize
$sums | ForEach-Object { Write-Host $_ }
Write-Host "`nTest it:  msiexec /i `"$msi`" /l*v `"$env:TEMP\chronomancer-install.log`""

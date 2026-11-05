# =============================================================================
# build.ps1 - compile a Jack application together with the tensor library
# =============================================================================
# Jack has no package manager: an application "imports" the library simply by
# being compiled into the same output folder.  This script stages
#     src/*.jack  (library)  +  <app>/*.jack  (entry point)
# into build/<app>/ and runs the nand2tetris JackCompiler on that folder.
#
# Examples:
#   .\tools\build.ps1                              # build apps/Cannon
#   .\tools\build.ps1 -App apps/TicTacToe          # build the second game
#   .\tools\build.ps1 -App src                     # build the workbench demo
#   .\tools\build.ps1 -JackCompiler "C:\nand2tetris\tools\JackCompiler.bat"
# =============================================================================

[CmdletBinding()]
param(
    [string] $App = "apps/Cannon",
    [string] $JackCompiler = "",
    [switch] $Run
)

$ErrorActionPreference = "Stop"

$root   = Split-Path -Parent $PSScriptRoot
$srcDir = Join-Path $root "src"

function Resolve-AppDir {
    param([string] $path)
    if ([System.IO.Path]::IsPathRooted($path)) { return $path }
    return (Join-Path $root $path)
}

function Find-JackCompiler {
    param([string] $explicit)

    if ($explicit) {
        if (Test-Path -LiteralPath $explicit) {
            return (Resolve-Path -LiteralPath $explicit).Path
        }
        throw "JackCompiler not found at: $explicit"
    }

    $candidates = @()

    if ($env:NAND2TETRIS_HOME) {
        $candidates += (Join-Path $env:NAND2TETRIS_HOME "tools\JackCompiler.bat")
    }

    $candidates += (Join-Path $root "..\nand2tetris\nand2tetris\tools\JackCompiler.bat")
    $candidates += (Join-Path $root "..\nand2tetris\tools\JackCompiler.bat")
    $candidates += (Join-Path $root "..\..\nand2tetris\nand2tetris\tools\JackCompiler.bat")

    foreach ($c in $candidates) {
        if (Test-Path -LiteralPath $c) {
            return (Resolve-Path -LiteralPath $c).Path
        }
    }

    $cmd = Get-Command JackCompiler.bat -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }
    $cmd = Get-Command JackCompiler -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    return $null
}

# --- resolve app + output folder --------------------------------------------
$appDir = Resolve-AppDir $App
if (-not (Test-Path -LiteralPath $appDir)) {
    throw "App directory not found: $appDir"
}

$resolvedApp = (Resolve-Path -LiteralPath $appDir).Path
$resolvedSrc = (Resolve-Path -LiteralPath $srcDir).Path
$isDemo      = ($resolvedApp -eq $resolvedSrc)

$appLeaf = Split-Path -Leaf $resolvedApp
if ($isDemo) { $appLeaf = "demo" }

$buildDir = Join-Path (Join-Path $root "build") $appLeaf

if (Test-Path -LiteralPath $buildDir) {
    Remove-Item -LiteralPath $buildDir -Recurse -Force
}
New-Item -ItemType Directory -Path $buildDir -Force | Out-Null

# --- stage sources -----------------------------------------------------------
Get-ChildItem -LiteralPath $srcDir -Filter *.jack | ForEach-Object {
    if ($isDemo -or ($_.Name -ne "Main.jack")) {
        Copy-Item -LiteralPath $_.FullName -Destination $buildDir
    }
}

if (-not $isDemo) {
    Get-ChildItem -LiteralPath $appDir -Filter *.jack | ForEach-Object {
        Copy-Item -LiteralPath $_.FullName -Destination $buildDir
    }
}

# --- compile ----------------------------------------------------------------
$compiler = Find-JackCompiler $JackCompiler
if (-not $compiler) {
    Write-Host ""
    Write-Host "JackCompiler was not found." -ForegroundColor Yellow
    Write-Host "  Pass its path with -JackCompiler, or set NAND2TETRIS_HOME."
    Write-Host "  Jack sources have been staged in: $buildDir"
    Write-Host ""
    exit 1
}

# --- stage the nand2tetris OS so the emulator can boot Sys.init -------------
$osDir = Join-Path (Split-Path -Parent $compiler) "OS"
if (Test-Path -LiteralPath $osDir) {
    Get-ChildItem -LiteralPath $osDir -Filter *.vm | Copy-Item -Destination $buildDir -Force
} else {
    Write-Host ""
    Write-Host "OS folder not found next to JackCompiler; relying on the emulator's built-in OS." -ForegroundColor Yellow
}

Write-Host "Compiling $buildDir"
Write-Host "  using $compiler"
& $compiler $buildDir
if ($LASTEXITCODE -ne 0) {
    throw "JackCompiler failed with exit code $LASTEXITCODE"
}

$vmCount = (Get-ChildItem -LiteralPath $buildDir -Filter *.vm | Measure-Object).Count
Write-Host ""
Write-Host "Compiled $vmCount .vm files into: $buildDir" -ForegroundColor Green
Write-Host "Open the VM Emulator and load that folder to run."

if ($Run) {
    $vmEmulator = Join-Path (Split-Path -Parent $compiler) "VMEmulator.bat"
    if (Test-Path -LiteralPath $vmEmulator) {
        Start-Process -FilePath $vmEmulator
    } else {
        Write-Host "VMEmulator.bat not found next to JackCompiler." -ForegroundColor Yellow
    }
}

param(
    [string]$QtRoot,
    [string]$WinRarExe
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

function Find-Program([string[]]$Candidates, [string]$Label) {
    foreach ($candidate in $Candidates) {
        if ($candidate -and (Test-Path -LiteralPath $candidate -PathType Leaf)) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }
    throw "找不到 $Label。请安装所需工具，或在命令行中指定路径。"
}

function Run-Checked([string]$Program, [string[]]$Arguments, [string]$Step) {
    Write-Host "`n==> $Step" -ForegroundColor Cyan
    & $Program @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "$Step 失败（退出码 $LASTEXITCODE）。"
    }
}

$projectRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
$buildDir = Join-Path $projectRoot 'build\SingleFileRelease'
$distDir = Join-Path $projectRoot 'dist'
$previousCache = Join-Path $projectRoot 'build\Release\CMakeCache.txt'

if (-not $QtRoot -and (Test-Path -LiteralPath $previousCache)) {
    $cacheText = Get-Content -LiteralPath $previousCache -Raw
    $qtMatch = [regex]::Match($cacheText, '(?m)^Qt6_DIR:PATH=(.+)[/\\]lib[/\\]cmake[/\\]Qt6\s*$')
    if ($qtMatch.Success) { $QtRoot = $qtMatch.Groups[1].Value.Trim() }
}
if (-not $QtRoot) {
    $qtCandidates = @(Get-ChildItem 'C:\Qt' -Directory -ErrorAction SilentlyContinue |
        Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'mingw_64\bin\windeployqt.exe') -PathType Leaf } |
        Sort-Object Name -Descending)
    if ($qtCandidates.Count -gt 0) { $QtRoot = Join-Path $qtCandidates[0].FullName 'mingw_64' }
}
if (-not $QtRoot -or -not (Test-Path -LiteralPath (Join-Path $QtRoot 'bin\windeployqt.exe') -PathType Leaf)) {
    throw '找不到 Qt MinGW 套件。可在 PowerShell 中使用 -QtRoot 指定，例如 C:\Qt\6.9.3\mingw_64。'
}
$QtRoot = (Resolve-Path -LiteralPath $QtRoot).Path

$cmakeCommand = Get-Command cmake.exe -ErrorAction SilentlyContinue
$ninjaCommand = Get-Command ninja.exe -ErrorAction SilentlyContinue
$rarCommand = Get-Command Rar.exe -ErrorAction SilentlyContinue
$cmakeFromPath = if ($cmakeCommand) { $cmakeCommand.Source } else { $null }
$ninjaFromPath = if ($ninjaCommand) { $ninjaCommand.Source } else { $null }
$rarFromPath = if ($rarCommand) { $rarCommand.Source } else { $null }
$cmakeExe = Find-Program @($cmakeFromPath, 'C:\Qt\Tools\CMake_64\bin\cmake.exe') 'CMake'
$ninjaExe = Find-Program @($ninjaFromPath, 'C:\Qt\Tools\Ninja\ninja.exe') 'Ninja'
$rarExe = Find-Program @($WinRarExe, $rarFromPath, 'C:\Program Files\WinRAR\Rar.exe', 'C:\Program Files (x86)\WinRAR\Rar.exe') 'WinRAR 命令行程序 Rar.exe'
$sfxSource = Find-Program @((Join-Path (Split-Path -Parent $rarExe) 'Default64.SFX')) 'WinRAR 64 位 SFX 模块'

$compilerExe = $null
if (Test-Path -LiteralPath $previousCache) {
    $compilerMatch = [regex]::Match($cacheText, '(?m)^CMAKE_CXX_COMPILER:STRING=(.+)\s*$')
    if ($compilerMatch.Success -and (Test-Path -LiteralPath $compilerMatch.Groups[1].Value.Trim() -PathType Leaf)) {
        $compilerExe = $compilerMatch.Groups[1].Value.Trim()
    }
}
if (-not $compilerExe) {
    $compilerExe = Get-ChildItem 'C:\Qt\Tools' -Directory -Filter 'mingw*' -ErrorAction SilentlyContinue |
        Sort-Object Name -Descending |
        ForEach-Object { Join-Path $_.FullName 'bin\g++.exe' } |
        Where-Object { Test-Path -LiteralPath $_ -PathType Leaf } |
        Select-Object -First 1
}
if (-not $compilerExe) { throw '找不到 MinGW C++ 编译器。请在 Qt Maintenance Tool 中安装 MinGW。' }

$versionMatch = [regex]::Match((Get-Content -LiteralPath (Join-Path $projectRoot 'CMakeLists.txt') -Raw),
    'project\s*\(\s*BackpackTools\s+VERSION\s+([0-9]+\.[0-9]+\.[0-9]+)')
if (-not $versionMatch.Success) { throw '无法从 CMakeLists.txt 读取项目版本号。' }
$version = $versionMatch.Groups[1].Value
$iconPath = Join-Path $projectRoot 'assets\backpack-logo.ico'
if (-not (Test-Path -LiteralPath $iconPath -PathType Leaf)) {
    throw "找不到程序图标：$iconPath"
}

$env:Path = (Join-Path $QtRoot 'bin') + ';' + (Split-Path -Parent $compilerExe) + ';' +
    (Split-Path -Parent $cmakeExe) + ';' + (Split-Path -Parent $ninjaExe) + ';' + $env:Path

New-Item -ItemType Directory -Path $buildDir, $distDir -Force | Out-Null
$buildArgs = @('-S', $projectRoot, '-B', $buildDir, '-G', 'Ninja',
    '-DCMAKE_BUILD_TYPE=Release', "-DCMAKE_PREFIX_PATH=$QtRoot",
    "-DCMAKE_CXX_COMPILER=$compilerExe", "-DCMAKE_MAKE_PROGRAM=$ninjaExe")
Run-Checked $cmakeExe $buildArgs '配置 Release 构建'
Run-Checked $cmakeExe @('--build', $buildDir, '--config', 'Release') '编译程序'

$appExe = Join-Path $buildDir 'appBackpackTools.exe'
if (-not (Test-Path -LiteralPath $appExe -PathType Leaf)) { throw '编译完成，但未找到 appBackpackTools.exe。' }

$runId = [guid]::NewGuid().ToString('N')
$stageDir = Join-Path $buildDir "single-file-stage-$runId"
$commentFile = Join-Path $buildDir "sfx-$runId.txt"
$customSfx = Join-Path $buildDir "backpack-$runId.SFX"
$temporaryPackage = Join-Path $distDir "7DaysBackpackTools-v$version-$runId.building.exe"
$outputPackage = Join-Path $distDir "7DaysBackpackTools-v$version.exe"
$stagePrefix = [System.IO.Path]::GetFullPath($buildDir).TrimEnd('\') + '\'
$stageFullPath = [System.IO.Path]::GetFullPath($stageDir)
if (-not $stageFullPath.StartsWith($stagePrefix, [StringComparison]::OrdinalIgnoreCase)) {
    throw '临时打包目录不在构建目录内，已停止。'
}

$locationPushed = $false
try {
    New-Item -ItemType Directory -Path $stageDir | Out-Null
    $stageExe = Join-Path $stageDir 'appBackpackTools.exe'
    Copy-Item -LiteralPath $appExe -Destination $stageExe
    Copy-Item -LiteralPath (Join-Path $projectRoot 'LICENSE') -Destination (Join-Path $stageDir 'LICENSE')
    $deployExe = Join-Path $QtRoot 'bin\windeployqt.exe'
    Run-Checked $deployExe @('--release', '--qmldir', $projectRoot, '--compiler-runtime', $stageExe) '收集 Qt 运行依赖'

    Copy-Item -LiteralPath $sfxSource -Destination $customSfx
    & (Join-Path $projectRoot 'set-sfx-icon.ps1') -SfxModule $customSfx -IconFile $iconPath

    @'
;The comment below contains SFX script commands
TempMode
Setup=appBackpackTools.exe
Silent=1
'@ | Set-Content -LiteralPath $commentFile -Encoding Ascii

    Push-Location -LiteralPath $stageDir
    $locationPushed = $true
    Run-Checked $rarExe @('a', '-r', '-m5', '-idq', "-sfx$customSfx", "-z$commentFile", $temporaryPackage, '*') '生成单文件 EXE'
    Pop-Location
    $locationPushed = $false

    Run-Checked $rarExe @('t', '-idq', $temporaryPackage) '检查打包文件完整性'
    Move-Item -LiteralPath $temporaryPackage -Destination $outputPackage -Force
    Write-Host "`n完成：$outputPackage" -ForegroundColor Green
} finally {
    if ($locationPushed) { Pop-Location }
    if (Test-Path -LiteralPath $stageDir) { Remove-Item -LiteralPath $stageDir -Recurse -Force }
    if (Test-Path -LiteralPath $commentFile) { Remove-Item -LiteralPath $commentFile -Force }
    if (Test-Path -LiteralPath $customSfx) { Remove-Item -LiteralPath $customSfx -Force }
    if (Test-Path -LiteralPath $temporaryPackage) { Remove-Item -LiteralPath $temporaryPackage -Force }
}

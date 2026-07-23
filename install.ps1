#Requires -Version 7.0
<#
.SYNOPSIS
    在 Windows 上安装 superpowers-schema 到目标 OpenSpec 项目。
.DESCRIPTION
    将本仓库的 superpowers-schema 复制到目标项目的 openspec/schemas/ 下，
    复制补充命令到 .opencode/commands/，并设置默认 schema。
    支持新装和升级（覆盖旧版本）。
.PARAMETER ProjectPath
    目标项目根目录绝对路径。不传则交互式询问。
.EXAMPLE
    .\install.ps1
    .\install.ps1 -ProjectPath D:\code\my-app
    .\install.ps1 -ProjectPath D:\code\my-app -Upgrade
.NOTES
    如遇执行策略限制，运行：
    pwsh -ExecutionPolicy Bypass -File .\install.ps1
#>
[CmdletBinding()]
param(
    [string]$ProjectPath,
    [switch]$Upgrade
)

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true

# ============================================================
# 0. 定位 schema 源
# ============================================================
$scriptRoot   = $PSScriptRoot
$schemaSrc    = Join-Path $scriptRoot 'superpowers-schema'
$commandsSrc  = Join-Path $schemaSrc 'commands'

if (-not (Test-Path -LiteralPath (Join-Path $schemaSrc 'schema.yaml'))) {
    Write-Host "❌ 找不到 schema 源：$schemaSrc" -ForegroundColor Red
    Write-Host "   请在 superpowers-schema 仓库根目录运行此脚本。" -ForegroundColor Yellow
    exit 1
}

# ============================================================
# 1. 读取目标项目路径
# ============================================================
if (-not $ProjectPath) {
    Write-Host ""
    Write-Host "  superpowers-schema 安装脚本" -ForegroundColor Cyan
    Write-Host "  ----------------------------------------"
    Write-Host "  将把 schema 安装到目标项目的 openspec/schemas/ 下，" -ForegroundColor DarkGray
    Write-Host "  复制补充命令到 .opencode/commands/，并设置默认 schema。" -ForegroundColor DarkGray
    Write-Host ""
    $ProjectPath = Read-Host "请输入要安装到的项目根目录绝对路径"
}

if (-not $ProjectPath) {
    Write-Host "❌ 未提供项目路径，退出。" -ForegroundColor Red
    exit 1
}

# 规范化路径：展开 ~、去尾斜杠
if ($ProjectPath.StartsWith('~')) {
    $ProjectPath = $HOME + $ProjectPath.Substring(1)
}
$ProjectPath = $ProjectPath.TrimEnd('\/')

if (-not (Test-Path -LiteralPath $ProjectPath -PathType Container)) {
    Write-Host "❌ 路径不存在或不是目录：$ProjectPath" -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "目标项目：$ProjectPath" -ForegroundColor Green

# ============================================================
# 2. 检查 openspec CLI ≥ 1.4.1
# ============================================================
Write-Host ""
Write-Host "[1/6] 检查 openspec CLI..." -ForegroundColor Cyan

$openspecCmd = Get-Command openspec -ErrorAction SilentlyContinue
if (-not $openspecCmd) {
    Write-Host "❌ 未找到 openspec CLI。" -ForegroundColor Red
    Write-Host "   请先安装 OpenSpec ≥ 1.4.1：https://github.com/Fission-AI/OpenSpec" -ForegroundColor Yellow
    exit 1
}

$versionRaw = openspec --version 2>&1 | Out-String
$versionMatch = [regex]::Match($versionRaw, '(\d+\.\d+\.\d+)')
if (-not $versionMatch.Success) {
    Write-Host "⚠️ 无法解析 openspec 版本：$($versionRaw.Trim())" -ForegroundColor Yellow
    Write-Host "   跳过版本检查，继续安装。" -ForegroundColor Yellow
} else {
    $version = $versionMatch.Groups[1].Value
    if ([version]$version -lt [version]'1.4.1') {
        Write-Host "❌ openspec 版本过低：$version，需要 ≥ 1.4.1" -ForegroundColor Red
        Write-Host "   升级：https://github.com/Fission-AI/OpenSpec/releases" -ForegroundColor Yellow
        exit 1
    }
    Write-Host "   ✓ openspec $version" -ForegroundColor Green
}

# ============================================================
# 3. 检查目标项目是否已 openspec init
# ============================================================
Write-Host ""
Write-Host "[2/6] 检查 OpenSpec 初始化..." -ForegroundColor Cyan

$openspecDir = Join-Path $ProjectPath 'openspec'
if (-not (Test-Path -LiteralPath $openspecDir -PathType Container)) {
    Write-Host "   项目尚未初始化 OpenSpec，直接运行 openspec init..." -ForegroundColor Yellow
    Push-Location $ProjectPath
    try {
        openspec init --tools opencode
        if ($LASTEXITCODE -ne 0) {
            Write-Host "❌ openspec init 失败（exit $LASTEXITCODE）" -ForegroundColor Red
            exit 1
        }
    } finally {
        Pop-Location
    }
    Write-Host "   ✓ OpenSpec 已初始化" -ForegroundColor Green
} else {
    Write-Host "   ✓ openspec/ 目录已存在" -ForegroundColor Green
}

# ============================================================
# 4. 复制 schema（覆盖旧版本）
# ============================================================
Write-Host ""
Write-Host "[3/6] 复制 schema..." -ForegroundColor Cyan

$schemaDst = Join-Path $openspecDir 'schemas\superpowers-schema'
if (Test-Path -LiteralPath $schemaDst) {
    if (-not $Upgrade) {
        Write-Host "   目标已存在 schema：$schemaDst" -ForegroundColor Yellow
        $confirm = Read-Host "   覆盖？(y/N)"
        if ($confirm -ne 'y' -and $confirm -ne 'Y') {
            Write-Host "❌ 用户取消，退出。" -ForegroundColor Red
            exit 1
        }
    }
    Remove-Item -LiteralPath $schemaDst -Recurse -Force
    Write-Host "   已移除旧版本" -ForegroundColor DarkGray
}
# 先删后复制：目标不存在时 Copy-Item 会创建，内容 = 源内容
Copy-Item -LiteralPath $schemaSrc -Destination $schemaDst -Recurse -Force
Write-Host "   ✓ schema 已复制到 openspec\schemas\superpowers-schema" -ForegroundColor Green

# ============================================================
# 5. 复制补充命令
# ============================================================
Write-Host ""
Write-Host "[4/6] 复制补充命令..." -ForegroundColor Cyan

$commandsDst = Join-Path $ProjectPath '.opencode\commands'
if (-not (Test-Path -LiteralPath $commandsDst -PathType Container)) {
    New-Item -ItemType Directory -Path $commandsDst -Force | Out-Null
}

$cmdFiles = Get-ChildItem -LiteralPath $commandsSrc -Filter '*.md'
foreach ($f in $cmdFiles) {
    Copy-Item -LiteralPath $f.FullName -Destination $commandsDst -Force
}
$cmdCount = (Get-ChildItem -LiteralPath $commandsDst -Filter 'opsx-*.md').Count
Write-Host "   ✓ 已复制 $($cmdFiles.Count) 个命令文件（$cmdCount 个 opsx-*.md）" -ForegroundColor Green

# ============================================================
# 6. 设置默认 schema
# ============================================================
Write-Host ""
Write-Host "[5/6] 设置默认 schema..." -ForegroundColor Cyan

$configPath = Join-Path $openspecDir 'config.yaml'
if (-not (Test-Path -LiteralPath $configPath)) {
    Write-Host "   config.yaml 不存在，创建最小配置..." -ForegroundColor Yellow
    @"
schema: superpowers-schema
"@ | Set-Content -LiteralPath $configPath -Encoding UTF8
    Write-Host "   ✓ 已创建 openspec\config.yaml" -ForegroundColor Green
} else {
    $content = Get-Content -LiteralPath $configPath -Raw
    if ($content -match '(?m)^schema:\s*\S+') {
        $newContent = $content -replace '(?m)^schema:\s*\S+', 'schema: superpowers-schema'
        Set-Content -LiteralPath $configPath -Value $newContent -NoNewline -Encoding UTF8
        Write-Host "   ✓ 已更新 schema: superpowers-schema" -ForegroundColor Green
    } else {
        $append = "`nschema: superpowers-schema`n"
        Add-Content -LiteralPath $configPath -Value $append -Encoding UTF8
        Write-Host "   ✓ 已追加 schema: superpowers-schema" -ForegroundColor Green
    }
}

# ============================================================
# 7. 校验
# ============================================================
Write-Host ""
Write-Host "[6/6] 运行 schema 校验..." -ForegroundColor Cyan

Push-Location $ProjectPath
try {
    openspec schema validate superpowers-schema 2>&1 | ForEach-Object { Write-Host "   $_" -ForegroundColor DarkGray }
    if ($LASTEXITCODE -eq 0) {
        Write-Host "   ✓ schema 校验通过" -ForegroundColor Green
    } else {
        Write-Host "   ⚠️  schema 校验失败（exit $LASTEXITCODE）" -ForegroundColor Yellow
        Write-Host "      请检查 openspec/changes/ 下是否有冲突的旧 change" -ForegroundColor Yellow
    }
} finally {
    Pop-Location
}

# ============================================================
# 健康检查报告
# ============================================================
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host " 安装完成 - 健康检查" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "项目路径：$ProjectPath"
Write-Host "Schema：  $schemaDst"
Write-Host "命令目录：$commandsDst（$cmdCount 个 opsx-*.md）"
Write-Host ""
Write-Host "下一步："
Write-Host "  1. 在 OpenCode agent 会话内确认以下技能可用："
Write-Host "     brainstorming / writing-plans / using-git-worktrees /"
Write-Host "     subagent-driven-development / systematic-debugging /"
Write-Host "     finishing-a-development-branch"
Write-Host "  2. 创建第一个 change：/opsx-propose <change-name>"
Write-Host ""

$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$AppName = "Abingo Claude Gateway"
$DefaultBaseUrl = if ($env:ABINGO_CLAUDE_BASE_URL) { $env:ABINGO_CLAUDE_BASE_URL } else { "https://claude.abingo.xyz" }
$DefaultModel = if ($env:ABINGO_CLAUDE_MODEL) { $env:ABINGO_CLAUDE_MODEL } else { "claude-codex" }
$DefaultEffort = if ($env:ABINGO_CLAUDE_EFFORT_LEVEL) { $env:ABINGO_CLAUDE_EFFORT_LEVEL } else { "max" }
$DefaultTimeoutMs = if ($env:ABINGO_CLAUDE_TIMEOUT_MS) { $env:ABINGO_CLAUDE_TIMEOUT_MS } else { "600000" }
$DefaultPermissionMode = if ($env:ABINGO_CLAUDE_PERMISSION_MODE) { $env:ABINGO_CLAUDE_PERMISSION_MODE } else { "bypassPermissions" }

function Backup-File {
    param ([string]$Path)

    if (Test-Path -LiteralPath $Path) {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $BackupPath = "$Path.bak.$Timestamp"
        Copy-Item -LiteralPath $Path -Destination $BackupPath -Force
        Write-Host "Backed up existing file: $BackupPath"
    }
}

function Convert-SecureStringToPlainText {
    param ([System.Security.SecureString]$SecureString)

    $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)
    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}

function Get-ClaudeConfigDir {
    if ($env:ABINGO_CLAUDE_CONFIG_DIR) {
        return $env:ABINGO_CLAUDE_CONFIG_DIR
    }
    if ($env:ABINGO_CLAUDE_HOME) {
        return (Join-Path $env:ABINGO_CLAUDE_HOME ".claude")
    }
    return (Join-Path $env:USERPROFILE ".claude")
}

function Test-AbingoClaudeGateway {
    param (
        [string]$BaseUrl,
        [string]$Model,
        [string]$AuthToken
    )

    if ($env:ABINGO_CLAUDE_SKIP_TEST -eq "1") {
        Write-Host "Gateway test skipped."
        return
    }

    $Body = @{
        model = $Model
        messages = @(
            @{
                role = "user"
                content = "installer auth test"
            }
        )
    } | ConvertTo-Json -Depth 10

    Invoke-RestMethod `
        -Uri "$($BaseUrl.TrimEnd('/'))/v1/messages/count_tokens" `
        -Method Post `
        -Headers @{ Authorization = "Bearer $AuthToken" } `
        -ContentType "application/json" `
        -Body $Body `
        -TimeoutSec 20 `
        -ErrorAction Stop | Out-Null

    Write-Host "Gateway auth test passed." -ForegroundColor Green
}

Write-Host "=========================================================="
Write-Host "          $AppName Setup Tool"
Write-Host "=========================================================="
Write-Host "Gateway URL: $DefaultBaseUrl"
Write-Host "Default model: $DefaultModel"
Write-Host "Permission mode: $DefaultPermissionMode"
Write-Host "System: Windows PowerShell"
Write-Host ""

$NonInteractive = $env:ABINGO_CLAUDE_NONINTERACTIVE -eq "1"

if ($env:ABINGO_CLAUDE_BASE_URL -or $NonInteractive) {
    $BaseUrl = $DefaultBaseUrl
} else {
    $BaseUrl = Read-Host "Gateway URL, press Enter to use default [$DefaultBaseUrl]"
    if ([string]::IsNullOrWhiteSpace($BaseUrl)) {
        $BaseUrl = $DefaultBaseUrl
    }
}
$BaseUrl = $BaseUrl.TrimEnd("/")

if ($env:ABINGO_CLAUDE_MODEL -or $NonInteractive) {
    $Model = $DefaultModel
} else {
    $Model = Read-Host "Model name, press Enter to use default [$DefaultModel]"
    if ([string]::IsNullOrWhiteSpace($Model)) {
        $Model = $DefaultModel
    }
}

Write-Host ""

$AuthToken = if ($env:ABINGO_CLAUDE_KEY) { $env:ABINGO_CLAUDE_KEY } elseif ($env:ANTHROPIC_AUTH_TOKEN) { $env:ANTHROPIC_AUTH_TOKEN } else { "" }
if (-not [string]::IsNullOrWhiteSpace($AuthToken)) {
    Write-Host "Using Claude gateway token from environment."
} else {
    $SecureToken = Read-Host "Enter your Abingo Claude gateway token" -AsSecureString
    $AuthToken = Convert-SecureStringToPlainText $SecureToken
}

if ([string]::IsNullOrWhiteSpace($AuthToken)) {
    Write-Host "Error: token cannot be empty." -ForegroundColor Red
    exit 1
}

$ClaudeDir = Get-ClaudeConfigDir
$SettingsFile = Join-Path $ClaudeDir "settings.json"

New-Item -ItemType Directory -Force -Path $ClaudeDir | Out-Null
Backup-File $SettingsFile

$Settings = [ordered]@{
    env = [ordered]@{
        ANTHROPIC_AUTH_TOKEN = $AuthToken
        ANTHROPIC_BASE_URL = $BaseUrl
        ANTHROPIC_MODEL = $Model
        ANTHROPIC_DEFAULT_OPUS_MODEL = $Model
        ANTHROPIC_DEFAULT_SONNET_MODEL = $Model
        ANTHROPIC_DEFAULT_HAIKU_MODEL = $Model
        CLAUDE_CODE_SUBAGENT_MODEL = $Model
        CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY = "1"
        CLAUDE_CODE_EFFORT_LEVEL = $DefaultEffort
        CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK = "1"
        API_TIMEOUT_MS = $DefaultTimeoutMs
        CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC = "1"
    }
    permissions = [ordered]@{
        allow = @("Bash(*)")
        deny = @()
    }
    permissionMode = $DefaultPermissionMode
    theme = "auto"
}

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false
$Json = $Settings | ConvertTo-Json -Depth 20
[System.IO.File]::WriteAllText($SettingsFile, $Json + [Environment]::NewLine, $Utf8NoBom)

Write-Host ""
Write-Host "=========================================================="
Write-Host "          $AppName Setup Complete"
Write-Host "=========================================================="
Write-Host "Settings file: $SettingsFile"
Write-Host "Gateway URL: $BaseUrl"
Write-Host "Model: $Model"
Write-Host "Permission mode: $DefaultPermissionMode"
Write-Host "Allowed tools: Bash(*)"
Write-Host ""

Write-Host "Testing gateway token..."
try {
    Test-AbingoClaudeGateway -BaseUrl $BaseUrl -Model $Model -AuthToken $AuthToken
} catch {
    Write-Host "Gateway auth test failed." -ForegroundColor Red
    Write-Host $_.Exception.Message
    exit 2
}

Write-Host ""
Write-Host "Restart any existing Claude Code session, then run:"
Write-Host "  claude"
Write-Host ""
Write-Host "Done."

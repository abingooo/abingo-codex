$ErrorActionPreference = "Stop"

try {
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
} catch {}

$AppName = "Abingo Codex"
$BaseUrl = "https://codex.abingo.xyz/v1"
$DefaultModel = if ($env:ABINGO_CODEX_MODEL) { $env:ABINGO_CODEX_MODEL } else { "gpt-5.5" }
$ReasoningEffort = if ($env:ABINGO_CODEX_REASONING_EFFORT) { $env:ABINGO_CODEX_REASONING_EFFORT } else { "xhigh" }
$ContextWindow = if ($env:ABINGO_CODEX_CONTEXT_WINDOW) { [int]$env:ABINGO_CODEX_CONTEXT_WINDOW } else { 262144 }
$AutoCompactTokenLimit = if ($env:ABINGO_CODEX_AUTO_COMPACT_TOKEN_LIMIT) { [int]$env:ABINGO_CODEX_AUTO_COMPACT_TOKEN_LIMIT } else { 242000 }

if ($ContextWindow -le 0 -or $AutoCompactTokenLimit -le 0) {
    Write-Host "Error: context window values must be positive integers." -ForegroundColor Red
    exit 1
}

function Write-Title {
    Write-Host "=================================================="
    Write-Host "          $AppName Setup Tool"
    Write-Host "=================================================="
    Write-Host "Service URL: $BaseUrl"
    Write-Host "System: Windows PowerShell"
    Write-Host "Context window: $ContextWindow"
    Write-Host "Auto compact limit: $AutoCompactTokenLimit"
    Write-Host "Reasoning effort: $ReasoningEffort"
    Write-Host ""
}

function Backup-File {
    param (
        [string]$Path
    )

    if (Test-Path $Path) {
        $Timestamp = Get-Date -Format "yyyyMMdd_HHmmss"
        $BackupPath = "$Path.bak.$Timestamp"
        Copy-Item $Path $BackupPath -Force
        Write-Host "Backed up existing file: $BackupPath"
    }
}

function Convert-SecureStringToPlainText {
    param (
        [System.Security.SecureString]$SecureString
    )

    $BSTR = [Runtime.InteropServices.Marshal]::SecureStringToBSTR($SecureString)

    try {
        return [Runtime.InteropServices.Marshal]::PtrToStringBSTR($BSTR)
    } finally {
        [Runtime.InteropServices.Marshal]::ZeroFreeBSTR($BSTR)
    }
}

function Test-AbingoCodexService {
    param (
        [string]$ApiKey
    )

    try {
        Invoke-RestMethod `
            -Uri "$BaseUrl/models" `
            -Headers @{ Authorization = "Bearer $ApiKey" } `
            -Method Get `
            -TimeoutSec 20 `
            -ErrorAction Stop | Out-Null

        Write-Host "Connection test passed." -ForegroundColor Green
    } catch {
        Write-Host "Connection test failed, but the configuration has been written." -ForegroundColor Yellow
        Write-Host $_.Exception.Message
    }
}

Write-Title

$Model = Read-Host "Model name, press Enter to use default [$DefaultModel]"

if ([string]::IsNullOrWhiteSpace($Model)) {
    $Model = $DefaultModel
}

Write-Host ""

$ApiKey = if ($env:ABINGO_CODEX_KEY) { $env:ABINGO_CODEX_KEY } elseif ($env:OPENAI_API_KEY) { $env:OPENAI_API_KEY } else { "" }
if (-not [string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "Using API key from environment."
} else {
    $SecureKey = Read-Host "Enter your Abingo Codex key, usually starting with sk-" -AsSecureString
    $ApiKey = Convert-SecureStringToPlainText $SecureKey
}

if ([string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Host "Error: key cannot be empty." -ForegroundColor Red
    exit 1
}

if (-not $ApiKey.StartsWith("sk-")) {
    Write-Host "Warning: the key you entered does not start with 'sk-'. Please make sure it is correct." -ForegroundColor Yellow
}

$CodexDir = Join-Path $env:USERPROFILE ".codex"
$ConfigFile = Join-Path $CodexDir "config.toml"
$AuthFile = Join-Path $CodexDir "auth.json"

New-Item -ItemType Directory -Force -Path $CodexDir | Out-Null

Backup-File $ConfigFile
Backup-File $AuthFile

$ConfigLines = @(
    'model_provider = "abingo_codex"',
    "model = `"$Model`"",
    "review_model = `"$Model`"",
    "model_reasoning_effort = `"$ReasoningEffort`"",
    'disable_response_storage = true',
    'network_access = "enabled"',
    'windows_wsl_setup_acknowledged = true',
    "model_context_window = $ContextWindow",
    "model_auto_compact_token_limit = $AutoCompactTokenLimit",
    '',
    '[model_providers.abingo_codex]',
    'name = "Abingo Codex"',
    "base_url = `"$BaseUrl`"",
    'wire_api = "responses"',
    'requires_openai_auth = true'
)

$AuthObject = @{
    OPENAI_API_KEY = $ApiKey
}

$AuthJson = $AuthObject | ConvertTo-Json -Depth 3

$Utf8NoBom = New-Object System.Text.UTF8Encoding $false

[System.IO.File]::WriteAllLines($ConfigFile, $ConfigLines, $Utf8NoBom)
[System.IO.File]::WriteAllText($AuthFile, $AuthJson, $Utf8NoBom)

Write-Host ""
Write-Host "=================================================="
Write-Host "          $AppName Setup Complete"
Write-Host "=================================================="
Write-Host "Config file: $ConfigFile"
Write-Host "Auth file: $AuthFile"
Write-Host "Service URL: $BaseUrl"
Write-Host "Default model: $Model"
Write-Host "Reasoning effort: $ReasoningEffort"
Write-Host "Context window: $ContextWindow"
Write-Host "Auto compact limit: $AutoCompactTokenLimit"
Write-Host ""

Write-Host "Testing service connection..."
Test-AbingoCodexService $ApiKey

Write-Host ""

$CodexCommand = Get-Command codex -ErrorAction SilentlyContinue

if ($CodexCommand) {
    Write-Host "Codex CLI detected. You can now run:"
    Write-Host "  codex"
} else {
    Write-Host "The 'codex' command was not found." -ForegroundColor Yellow
    Write-Host "The Abingo Codex configuration has been written, but Codex CLI is required to run 'codex'."
    Write-Host "If Codex CLI is already installed, close this terminal and open a new one."
}

Write-Host ""
Write-Host "Done."

# Abingo Codex

Cross-platform installers for configuring local AI coding CLIs to use Abingo gateways.

This repository configures:

```text
Codex CLI   -> https://codex.abingo.xyz/v1
Claude Code -> https://claude.abingo.xyz
```

It does not include secret keys and does not install the upstream `codex` or `claude` CLI binaries.

## Installers

```text
install.sh           Linux / macOS Codex installer
install.ps1          Windows PowerShell Codex installer
install.py           Cross-platform Codex fallback installer

claude_install.sh    Linux / macOS Claude Code gateway installer
claude_install.ps1   Windows PowerShell Claude Code gateway installer
claude_install.py    Cross-platform Claude Code fallback installer
```

## Quick Start

### Codex CLI

Use this when you want the `codex` command to use Abingo Codex.

Linux / macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.sh | sh
```

Linux server or non-interactive install:

```bash
export ABINGO_CODEX_KEY="sk-..."
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.sh | sh
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.ps1 | iex
```

After setup:

```bash
codex
```

### Claude Code Gateway

Use this when you want the `claude` command to use the Abingo Claude gateway.

Linux / macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/claude_install.sh | sh
```

Linux server or non-interactive install:

```bash
export ABINGO_CLAUDE_KEY="your-gateway-token"
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/claude_install.sh | sh
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/claude_install.ps1 | iex
```

Windows PowerShell non-interactive install:

```powershell
$env:ABINGO_CLAUDE_KEY = "your-gateway-token"
$env:ABINGO_CLAUDE_NONINTERACTIVE = "1"
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/claude_install.ps1 | iex
```

After setup:

```bash
claude
```

## What Gets Written

Existing files are backed up before being replaced. Backup names look like:

```text
config.toml.bak.20260507_123456
settings.json.bak.20260507_123456
```

Codex configuration:

```text
Linux / macOS: ~/.codex/config.toml
Linux / macOS: ~/.codex/auth.json
Windows:       C:\Users\<YourUserName>\.codex\config.toml
Windows:       C:\Users\<YourUserName>\.codex\auth.json
```

Claude Code configuration:

```text
Linux / macOS: ~/.claude/settings.json
Windows:       C:\Users\<YourUserName>\.claude\settings.json
```

## Defaults

### Codex

```text
Service URL: https://codex.abingo.xyz/v1
Default model: gpt-5.5
Reasoning effort: xhigh
Context window: 262144
Auto compact token limit: 242000
Auth env: ABINGO_CODEX_KEY, then OPENAI_API_KEY
```

If `gpt-5.5` is not available, rerun the installer and enter `gpt-5.4` when prompted for the model.

### Claude Code

```text
Gateway URL: https://claude.abingo.xyz
Default model: claude-codex
Permission mode: bypassPermissions
Allowed tools: Bash(*)
Timeout: 600000 ms
Auth env: ABINGO_CLAUDE_KEY, then ANTHROPIC_AUTH_TOKEN
```

There is no default token. The installer must receive a token from the environment or from interactive input.

## Python Fallback

Use the Python installers if the shell or PowerShell installer is not suitable.

Codex:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.py | python3 -
```

Codex on Windows:

```powershell
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.py | py -3 -
```

Claude Code:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/claude_install.py | python3 -
```

Claude Code non-interactive:

```bash
export ABINGO_CLAUDE_KEY="your-gateway-token"
export ABINGO_CLAUDE_NONINTERACTIVE="1"
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/claude_install.py | python3 -
```

## Environment Variables

### Codex Variables

| Variable | Purpose |
| --- | --- |
| `ABINGO_CODEX_KEY` | Abingo Codex API key. |
| `OPENAI_API_KEY` | Fallback key variable used by Codex auth. |
| `ABINGO_CODEX_MODEL` | Override the default model. |
| `ABINGO_CODEX_REASONING_EFFORT` | Override reasoning effort. |
| `ABINGO_CODEX_CONTEXT_WINDOW` | Override model context window. |
| `ABINGO_CODEX_AUTO_COMPACT_TOKEN_LIMIT` | Override auto compact token limit. |

### Claude Code Variables

| Variable | Purpose |
| --- | --- |
| `ABINGO_CLAUDE_KEY` | Abingo Claude gateway token. |
| `ANTHROPIC_AUTH_TOKEN` | Fallback Claude auth token variable. |
| `ABINGO_CLAUDE_BASE_URL` | Override the gateway URL. |
| `ABINGO_CLAUDE_MODEL` | Override the gateway model. |
| `ABINGO_CLAUDE_EFFORT_LEVEL` | Override Claude Code effort level. |
| `ABINGO_CLAUDE_TIMEOUT_MS` | Override API timeout in milliseconds. |
| `ABINGO_CLAUDE_PERMISSION_MODE` | Override Claude Code permission mode. |
| `ABINGO_CLAUDE_CONFIG_DIR` | Write `settings.json` to a custom directory. |
| `ABINGO_CLAUDE_HOME` | Use a custom home directory for `.claude`. |
| `ABINGO_CLAUDE_SKIP_TEST` | Set to `1` to skip the gateway auth test. |
| `ABINGO_CLAUDE_NONINTERACTIVE` | Set to `1` to use defaults without URL/model prompts. |

## Manual Tests

Codex model list:

```bash
curl https://codex.abingo.xyz/v1/models \
  -H "Authorization: Bearer YOUR_ABINGO_CODEX_KEY"
```

Codex chat request:

```bash
curl https://codex.abingo.xyz/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ABINGO_CODEX_KEY" \
  -d '{"model":"gpt-5.5","stream":false,"messages":[{"role":"user","content":"Please reply with success only."}]}'
```

Claude gateway auth:

```bash
curl https://claude.abingo.xyz/v1/messages/count_tokens \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ABINGO_CLAUDE_TOKEN" \
  -d '{"model":"claude-codex","messages":[{"role":"user","content":"installer auth test"}]}'
```

## Updating

Run the same installer again whenever you want to refresh local configuration. The old config files will be backed up automatically before new files are written.

## Troubleshooting

### `codex` or `claude` was not found

These installers only write configuration files. Install the upstream CLI first, then open a new terminal and try again.

### Connection test failed

Check the key or token, selected model, network access, and gateway status.

### Non-interactive install says the key or token is empty

Set the key in the same shell session before running the installer:

```bash
export ABINGO_CODEX_KEY="sk-..."
export ABINGO_CLAUDE_KEY="your-gateway-token"
```

## Security

Do not publish or commit real keys or tokens.

These local files contain secrets:

```text
~/.codex/auth.json
~/.claude/settings.json
```

Backup files can also contain old secrets, so keep them private.

## Repository

```text
https://github.com/abingooo/abingo-codex
```

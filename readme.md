# Abingo Codex Setup Tool

A simple cross-platform setup tool for configuring Codex CLI with Abingo Codex.

## Overview

Abingo Codex Setup Tool helps you quickly configure Codex CLI to use the Abingo Codex service.

It automatically creates or updates the following local Codex configuration files:

```text
~/.codex/config.toml
~/.codex/auth.json
```

On Windows, the files are located at:

```text
C:\Users\<YourUserName>\.codex\config.toml
C:\Users\<YourUserName>\.codex\auth.json
```

Existing configuration files will be backed up automatically before new files are written.

## Requirements

### Linux / macOS

Required:

- `sh`
- `curl`
- Network access to `https://codex.abingo.xyz`
- An Abingo Codex key, usually starting with `sk-`

Optional:

- Python 3, only needed for the Python fallback installer
- Codex CLI, required to run `codex` after setup

### Windows

Required:

- PowerShell
- Network access to `https://codex.abingo.xyz`
- An Abingo Codex key, usually starting with `sk-`

Optional:

- Python 3, only needed for the Python fallback installer
- Codex CLI, required to run `codex` after setup

This repository does not include any secret keys. You need to enter your own Abingo Codex key during setup.

## Quick Setup

### Linux / macOS

Recommended:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.sh | sh
```

Python fallback:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.py | python3 -
```

### Windows PowerShell

Recommended:

```powershell
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.ps1 | iex
```

Python fallback:

```powershell
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.py | py -3 -
```

## Setup Prompts

During setup, the script will ask for:

```text
Model name
```

Press Enter to use the default model:

```text
gpt-5.5
```

Then it will ask for:

```text
Abingo Codex key
```

Enter the key provided to you. It usually starts with:

```text
sk-
```

## Default Configuration

The setup tool writes the following default configuration:

```text
Service name: Abingo Codex
Service URL: https://codex.abingo.xyz/v1
Default model: gpt-5.5
Fallback model: gpt-5.4
```

After setup, run:

```bash
codex
```

## If GPT-5.5 Is Not Available

If `gpt-5.5` is not available, run the setup command again and enter:

```text
gpt-5.4
```

when prompted for the model name.

## What the Setup Tool Does

The installer will:

- Create the `~/.codex` directory if it does not exist
- Back up existing Codex configuration files
- Write a new `config.toml`
- Write a new `auth.json`
- Configure Codex CLI to use Abingo Codex
- Test the Abingo Codex service connection
- Check whether the `codex` command exists

If existing configuration files are found, they will be backed up automatically, for example:

```text
config.toml.bak.20260507_123456
auth.json.bak.20260507_123456
```

## Generated Configuration

The generated `config.toml` will look similar to this:

```toml
model_provider = "abingo_codex"
model = "gpt-5.5"
review_model = "gpt-5.5"
model_reasoning_effort = "high"
disable_response_storage = true
network_access = "enabled"
model_context_window = 100000
model_auto_compact_token_limit = 90000

[model_providers.abingo_codex]
name = "Abingo Codex"
base_url = "https://codex.abingo.xyz/v1"
wire_api = "responses"
requires_openai_auth = true
```

On Windows, the generated configuration also includes:

```toml
windows_wsl_setup_acknowledged = true
```

The generated `auth.json` will look like this:

```json
{
  "OPENAI_API_KEY": "YOUR_ABINGO_CODEX_KEY"
}
```

## Manual Test

After setup, you can test the service with:

```bash
curl https://codex.abingo.xyz/v1/models \
  -H "Authorization: Bearer YOUR_ABINGO_CODEX_KEY"
```

You can also test a chat request:

```bash
curl https://codex.abingo.xyz/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ABINGO_CODEX_KEY" \
  -d '{"model":"gpt-5.5","stream":false,"messages":[{"role":"user","content":"Please reply with success only."}]}'
```

Replace:

```text
YOUR_ABINGO_CODEX_KEY
```

with your actual Abingo Codex key.

## Updating the Setup

To update your local configuration, simply run the setup command again.

Linux / macOS:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.sh | sh
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.ps1 | iex
```

The setup tool will automatically back up old configuration files before writing new ones.

## Installer Files

This repository provides three installers:

```text
install.sh    Linux / macOS shell installer
install.ps1   Windows PowerShell installer
install.py    Cross-platform Python fallback installer
```

Recommended usage:

```text
Linux / macOS:     install.sh
Windows:           install.ps1
Fallback:          install.py
```

## Security Notes

Do not share your Abingo Codex key publicly.

Do not commit any of the following files to GitHub:

```text
auth.json
config.toml
.env
*.pem
*.key
*.json
```

This repository should only contain setup scripts and documentation.

## Troubleshooting

### The `codex` command was not found

The setup tool only configures Codex CLI. You still need Codex CLI installed to run:

```bash
codex
```

After installing Codex CLI, close the terminal and open a new one.

### Connection test failed

Check:

- Your Abingo Codex key is correct
- Your network can access `https://codex.abingo.xyz`
- The Abingo Codex service is currently available
- The selected model is available

### GPT-5.5 does not work

Run the setup tool again and enter:

```text
gpt-5.4
```

when prompted for the model name.

## Repository

```text
https://github.com/abingooo/abingo-codex
```

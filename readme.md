# Abingo Codex Setup Tool

A simple cross-platform setup script for configuring Codex CLI with Abingo Codex.

## Overview

This tool automatically configures Codex CLI to use the Abingo Codex service.

It creates or updates the following local Codex configuration files:

```text
~/.codex/config.toml
~/.codex/auth.json
```

On Windows, the files are located at:

```text
C:\Users\<YourUserName>\.codex\config.toml
C:\Users\<YourUserName>\.codex\auth.json
```

The script backs up existing configuration files before writing new ones.

## Requirements

Before running the setup script, make sure you have:

- Python 3 installed
- Network access to `https://codex.abingo.xyz`
- An Abingo Codex key, usually in the format `sk-xxxx`
- Codex CLI installed if you want to run `codex` after setup

This repository does not include any secret keys. You need to enter your own Abingo Codex key during setup.

## Quick Setup

### Linux / macOS

Run this command in your terminal:

```bash
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.py | python3 -
```

### Windows PowerShell

Run this command in PowerShell:

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

Enter the key provided to you, usually starting with:

```text
sk-
```

## Default Configuration

The script writes the following default configuration:

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

## What the Script Does

The installer will:

- Create the `~/.codex` directory if it does not exist
- Back up existing Codex configuration files
- Write a new `config.toml`
- Write a new `auth.json`
- Test the Abingo Codex service connection
- Check whether the `codex` command exists

If existing configuration files are found, they will be backed up automatically, for example:

```text
config.toml.bak.20260507_123456
auth.json.bak.20260507_123456
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
curl -fsSL https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.py | python3 -
```

Windows PowerShell:

```powershell
irm https://raw.githubusercontent.com/abingooo/abingo-codex/main/install.py | py -3 -
```

The script will automatically back up old configuration files before writing new ones.

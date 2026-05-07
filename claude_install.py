#!/usr/bin/env python3
# -*- coding: utf-8 -*-

import json
import os
import platform
import shutil
import sys
import time
import urllib.error
import urllib.request
from pathlib import Path

APP_NAME = "Abingo Claude Gateway"
DEFAULT_BASE_URL = os.environ.get("ABINGO_CLAUDE_BASE_URL", "https://claude.abingo.xyz")
DEFAULT_MODEL = os.environ.get("ABINGO_CLAUDE_MODEL", "claude-codex")
DEFAULT_EFFORT = os.environ.get("ABINGO_CLAUDE_EFFORT_LEVEL", "max")
DEFAULT_TIMEOUT_MS = os.environ.get("ABINGO_CLAUDE_TIMEOUT_MS", "600000")
DEFAULT_PERMISSION_MODE = os.environ.get("ABINGO_CLAUDE_PERMISSION_MODE", "bypassPermissions")
NONINTERACTIVE = os.environ.get("ABINGO_CLAUDE_NONINTERACTIVE") == "1"


def open_console():
    input_stream = sys.stdin
    output_stream = sys.stdout

    try:
        if os.name == "nt":
            input_stream = open("CONIN$", "r", encoding="utf-8", errors="ignore")
            output_stream = open("CONOUT$", "w", encoding="utf-8", errors="ignore")
        else:
            input_stream = open("/dev/tty", "r", encoding="utf-8", errors="ignore")
            output_stream = open("/dev/tty", "w", encoding="utf-8", errors="ignore")
    except Exception:
        pass

    return input_stream, output_stream


IN_STREAM, OUT_STREAM = open_console()


def say(text=""):
    print(text, file=OUT_STREAM, flush=True)


def ask(question, default=None):
    prompt = f"{question} [{default}]: " if default is not None else f"{question}: "
    OUT_STREAM.write(prompt)
    OUT_STREAM.flush()

    answer = IN_STREAM.readline()
    if not answer:
        return default or ""

    answer = answer.strip()
    if not answer and default is not None:
        return default
    return answer


def env_value(*names):
    for name in names:
        value = os.environ.get(name)
        if value:
            return value.strip()
    return ""


def claude_config_dir():
    config_dir = env_value("ABINGO_CLAUDE_CONFIG_DIR")
    if config_dir:
        return Path(config_dir).expanduser()

    home_override = env_value("ABINGO_CLAUDE_HOME")
    if home_override:
        return Path(home_override).expanduser() / ".claude"

    return Path.home() / ".claude"


def backup_file(path):
    if path.exists():
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        backup_path = path.with_name(path.name + f".bak.{timestamp}")
        shutil.copy2(path, backup_path)
        say(f"Backed up existing file: {backup_path}")


def load_existing_settings(path):
    if not path.exists():
        return {}
    try:
        data = json.loads(path.read_text(encoding="utf-8-sig"))
        return data if isinstance(data, dict) else {}
    except Exception:
        return {}


def build_settings(existing, base_url, model, auth_token):
    settings = dict(existing)
    env = dict(settings.get("env") or {})

    env.update({
        "ANTHROPIC_AUTH_TOKEN": auth_token,
        "ANTHROPIC_BASE_URL": base_url.rstrip("/"),
        "ANTHROPIC_MODEL": model,
        "ANTHROPIC_DEFAULT_OPUS_MODEL": model,
        "ANTHROPIC_DEFAULT_SONNET_MODEL": model,
        "ANTHROPIC_DEFAULT_HAIKU_MODEL": model,
        "CLAUDE_CODE_SUBAGENT_MODEL": model,
        "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
        "CLAUDE_CODE_EFFORT_LEVEL": DEFAULT_EFFORT,
        "CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK": "1",
        "API_TIMEOUT_MS": DEFAULT_TIMEOUT_MS,
        "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1",
    })

    settings["env"] = env
    settings["permissions"] = {
        "allow": ["Bash(*)"],
        "deny": [],
    }
    settings["permissionMode"] = DEFAULT_PERMISSION_MODE
    settings.setdefault("theme", "auto")
    return settings


def write_settings(base_url, model, auth_token):
    config_dir = claude_config_dir()
    config_dir.mkdir(parents=True, exist_ok=True)
    settings_file = config_dir / "settings.json"

    existing = load_existing_settings(settings_file)
    backup_file(settings_file)

    settings = build_settings(existing, base_url, model, auth_token)
    settings_file.write_text(json.dumps(settings, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")

    try:
        os.chmod(settings_file, 0o600)
    except Exception:
        pass

    return settings_file


def test_gateway(base_url, model, auth_token):
    if env_value("ABINGO_CLAUDE_SKIP_TEST") in {"1", "true", "TRUE", "yes", "YES"}:
        return True, "Gateway test skipped."

    url = base_url.rstrip("/") + "/v1/messages/count_tokens"
    body = {
        "model": model,
        "messages": [
            {
                "role": "user",
                "content": "installer auth test",
            }
        ],
    }
    req = urllib.request.Request(
        url,
        data=json.dumps(body).encode("utf-8"),
        method="POST",
        headers={
            "Authorization": f"Bearer {auth_token}",
            "Content-Type": "application/json",
            "User-Agent": "abingo-claude-installer",
        },
    )

    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            if 200 <= resp.status < 300:
                return True, "Gateway auth test passed."
            return False, f"Gateway auth test failed. HTTP status: {resp.status}"
    except urllib.error.HTTPError as e:
        msg = f"Gateway auth test failed. HTTP status: {e.code}"
        try:
            body = e.read().decode("utf-8", errors="ignore")
            if body:
                msg += "\n" + body[:500]
        except Exception:
            pass
        return False, msg
    except Exception as e:
        return False, f"Gateway auth test failed: {e}"


def print_header():
    say("=" * 58)
    say(f"          {APP_NAME} Setup Tool")
    say("=" * 58)
    say(f"Gateway URL: {DEFAULT_BASE_URL}")
    say(f"Default model: {DEFAULT_MODEL}")
    say(f"Permission mode: {DEFAULT_PERMISSION_MODE}")
    say(f"System: {platform.system()} {platform.machine()}")
    say(f"Python: {platform.python_version()}")
    say()


def main():
    if sys.version_info < (3, 8):
        say("Python 3.8 or newer is recommended.")
        say(f"Current Python version: {platform.python_version()}")
        sys.exit(1)

    print_header()

    if env_value("ABINGO_CLAUDE_BASE_URL") or NONINTERACTIVE:
        base_url = DEFAULT_BASE_URL
    else:
        base_url = ask("Gateway URL, press Enter to use default", DEFAULT_BASE_URL)

    if env_value("ABINGO_CLAUDE_MODEL") or NONINTERACTIVE:
        model = DEFAULT_MODEL
    else:
        model = ask("Model name, press Enter to use default", DEFAULT_MODEL)

    say()
    auth_token = env_value("ABINGO_CLAUDE_KEY", "ANTHROPIC_AUTH_TOKEN")
    if auth_token:
        say("Using Claude gateway token from environment.")
    else:
        auth_token = ask("Enter your Abingo Claude gateway token")

    if not auth_token:
        say("Error: token cannot be empty.")
        say("Run this installer in an interactive terminal to enter the token when prompted.")
        say("Set ABINGO_CLAUDE_KEY or ANTHROPIC_AUTH_TOKEN for non-interactive installs.")
        sys.exit(1)

    settings_file = write_settings(base_url, model, auth_token)

    say()
    say("=" * 58)
    say(f"          {APP_NAME} Setup Complete")
    say("=" * 58)
    say(f"Settings file: {settings_file}")
    say(f"Gateway URL: {base_url.rstrip('/')}")
    say(f"Model: {model}")
    say(f"Permission mode: {DEFAULT_PERMISSION_MODE}")
    say("Allowed tools: Bash(*)")
    say()

    say("Testing gateway token...")
    ok, message = test_gateway(base_url, model, auth_token)
    say(message)
    if not ok:
        sys.exit(2)

    say()
    say("Restart any existing Claude Code session, then run:")
    say("  claude")
    say()
    say("Done.")


if __name__ == "__main__":
    main()

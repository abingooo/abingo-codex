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

APP_NAME = "Abingo Codex"
BASE_URL = "https://codex.abingo.xyz/v1"
DEFAULT_MODEL = os.environ.get("ABINGO_CODEX_MODEL", "gpt-5.5")
DEFAULT_REASONING_EFFORT = os.environ.get("ABINGO_CODEX_REASONING_EFFORT", "xhigh")
CONTEXT_WINDOW = int(os.environ.get("ABINGO_CODEX_CONTEXT_WINDOW", "262144"))
AUTO_COMPACT_TOKEN_LIMIT = int(os.environ.get("ABINGO_CODEX_AUTO_COMPACT_TOKEN_LIMIT", "242000"))

if CONTEXT_WINDOW <= 0 or AUTO_COMPACT_TOKEN_LIMIT <= 0:
    raise ValueError("Context window values must be positive integers.")


def open_console():
    """
    Support pipe-based execution, such as:

    Linux / macOS:
        curl -fsSL <url> | python3 -

    Windows PowerShell:
        irm <url> | py -3 -

    When a script is piped into Python through stdin, normal input() may not work.
    This function tries to open the real console device for interactive prompts.
    """
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
    if default is not None:
        prompt = f"{question} [{default}]: "
    else:
        prompt = f"{question}: "

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


def command_exists(command):
    return shutil.which(command) is not None


def backup_file(path):
    if path.exists():
        timestamp = time.strftime("%Y%m%d_%H%M%S")
        backup_path = path.with_name(path.name + f".bak.{timestamp}")
        shutil.copy2(path, backup_path)
        say(f"Backed up existing file: {backup_path}")


def toml_escape(value):
    return value.replace("\\", "\\\\").replace('"', '\\"')


def write_codex_config(model, api_key):
    codex_dir = Path.home() / ".codex"
    codex_dir.mkdir(parents=True, exist_ok=True)

    config_file = codex_dir / "config.toml"
    auth_file = codex_dir / "auth.json"

    backup_file(config_file)
    backup_file(auth_file)

    safe_model = toml_escape(model)
    safe_base_url = toml_escape(BASE_URL)
    safe_reasoning_effort = toml_escape(DEFAULT_REASONING_EFFORT)

    config_content = f'''model_provider = "abingo_codex"
model = "{safe_model}"
review_model = "{safe_model}"
model_reasoning_effort = "{safe_reasoning_effort}"
disable_response_storage = true
network_access = "enabled"
windows_wsl_setup_acknowledged = true
model_context_window = {CONTEXT_WINDOW}
model_auto_compact_token_limit = {AUTO_COMPACT_TOKEN_LIMIT}

[model_providers.abingo_codex]
name = "Abingo Codex"
base_url = "{safe_base_url}"
wire_api = "responses"
requires_openai_auth = true
'''

    auth_content = {
        "OPENAI_API_KEY": api_key
    }

    config_file.write_text(config_content, encoding="utf-8")
    auth_file.write_text(json.dumps(auth_content, indent=2, ensure_ascii=False), encoding="utf-8")

    try:
        os.chmod(config_file, 0o600)
        os.chmod(auth_file, 0o600)
    except Exception:
        pass

    return config_file, auth_file


def test_service(api_key):
    url = BASE_URL.rstrip("/") + "/models"

    req = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "User-Agent": "abingo-codex-installer"
        },
        method="GET"
    )

    try:
        with urllib.request.urlopen(req, timeout=20) as resp:
            if 200 <= resp.status < 300:
                return True, "Connection test passed."
            return False, f"Connection test failed. HTTP status: {resp.status}"

    except urllib.error.HTTPError as e:
        msg = f"Connection test failed. HTTP status: {e.code}"
        try:
            body = e.read().decode("utf-8", errors="ignore")
            if body:
                msg += "\n" + body[:500]
        except Exception:
            pass
        return False, msg

    except Exception as e:
        return False, f"Connection test failed: {e}"


def print_header():
    say("=" * 50)
    say(f"          {APP_NAME} Setup Tool")
    say("=" * 50)
    say(f"Service URL: {BASE_URL}")
    say(f"System: {platform.system()} {platform.machine()}")
    say(f"Python: {platform.python_version()}")
    say(f"Context window: {CONTEXT_WINDOW}")
    say(f"Auto compact limit: {AUTO_COMPACT_TOKEN_LIMIT}")
    say(f"Reasoning effort: {DEFAULT_REASONING_EFFORT}")
    say()


def print_codex_hint():
    say()
    say("The 'codex' command was not found.")
    say("The Abingo Codex configuration has been written, but Codex CLI is required to run 'codex'.")
    say()
    say("If Codex CLI is already installed, close this terminal and open a new one.")
    say("If it is not installed yet, please install Codex CLI first.")
    say()


def main():
    if sys.version_info < (3, 8):
        say("Python 3.8 or newer is recommended.")
        say(f"Current Python version: {platform.python_version()}")
        sys.exit(1)

    print_header()

    model = env_value("ABINGO_CODEX_MODEL") or ask("Model name, press Enter to use default", DEFAULT_MODEL)

    say()
    api_key = env_value("ABINGO_CODEX_KEY", "OPENAI_API_KEY")
    if api_key:
        say("Using API key from environment.")
    else:
        api_key = ask("Enter your Abingo Codex key, usually starting with sk-")

    if not api_key:
        say("Error: key cannot be empty.")
        sys.exit(1)

    if not api_key.startswith("sk-"):
        say("Warning: the key you entered does not start with 'sk-'. Please make sure it is correct.")

    config_file, auth_file = write_codex_config(model, api_key)

    say()
    say("=" * 50)
    say(f"          {APP_NAME} Setup Complete")
    say("=" * 50)
    say(f"Config file: {config_file}")
    say(f"Auth file: {auth_file}")
    say(f"Service URL: {BASE_URL}")
    say(f"Default model: {model}")
    say(f"Reasoning effort: {DEFAULT_REASONING_EFFORT}")
    say(f"Context window: {CONTEXT_WINDOW}")
    say(f"Auto compact limit: {AUTO_COMPACT_TOKEN_LIMIT}")
    say()

    say("Testing service connection...")
    ok, message = test_service(api_key)
    say(message)

    if command_exists("codex"):
        say()
        say("Codex CLI detected. You can now run:")
        say("  codex")
    else:
        print_codex_hint()

    say()
    say("Done.")


if __name__ == "__main__":
    main()

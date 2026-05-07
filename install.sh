#!/usr/bin/env sh

APP_NAME="Abingo Codex"
BASE_URL="https://codex.abingo.xyz/v1"
DEFAULT_MODEL="gpt-5.5"

say() {
  printf "%s\n" "$*"
}

prompt() {
  question="$1"
  default="$2"

  if [ -n "$default" ]; then
    printf "%s [%s]: " "$question" "$default" > /dev/tty
  else
    printf "%s: " "$question" > /dev/tty
  fi

  IFS= read -r answer < /dev/tty

  if [ -z "$answer" ] && [ -n "$default" ]; then
    answer="$default"
  fi

  printf "%s" "$answer"
}

prompt_secret() {
  question="$1"

  printf "%s: " "$question" > /dev/tty

  if command -v stty >/dev/null 2>&1; then
    stty -echo < /dev/tty 2>/dev/null || true
  fi

  IFS= read -r answer < /dev/tty

  if command -v stty >/dev/null 2>&1; then
    stty echo < /dev/tty 2>/dev/null || true
  fi

  printf "\n" > /dev/tty
  printf "%s" "$answer"
}

backup_file() {
  file="$1"

  if [ -f "$file" ]; then
    ts="$(date +%Y%m%d_%H%M%S)"
    backup="${file}.bak.${ts}"
    cp "$file" "$backup"
    say "Backed up existing file: $backup"
  fi
}

escape_toml() {
  printf "%s" "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

escape_json() {
  printf "%s" "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

say "=================================================="
say "          $APP_NAME Setup Tool"
say "=================================================="
say "Service URL: $BASE_URL"
say "System: $(uname -s) $(uname -m)"
say ""

if [ ! -r /dev/tty ]; then
  say "Error: interactive terminal is required."
  say "Please run this script from a normal terminal."
  exit 1
fi

MODEL="$(prompt "Model name, press Enter to use default" "$DEFAULT_MODEL")"

say ""

API_KEY="$(prompt_secret "Enter your Abingo Codex key, usually starting with sk-")"

if [ -z "$API_KEY" ]; then
  say "Error: key cannot be empty."
  exit 1
fi

case "$API_KEY" in
  sk-*) ;;
  *)
    say "Warning: the key you entered does not start with 'sk-'. Please make sure it is correct."
    ;;
esac

CODEX_DIR="$HOME/.codex"
CONFIG_FILE="$CODEX_DIR/config.toml"
AUTH_FILE="$CODEX_DIR/auth.json"

mkdir -p "$CODEX_DIR"

backup_file "$CONFIG_FILE"
backup_file "$AUTH_FILE"

SAFE_MODEL="$(escape_toml "$MODEL")"
SAFE_BASE_URL="$(escape_toml "$BASE_URL")"
SAFE_API_KEY="$(escape_json "$API_KEY")"

cat > "$CONFIG_FILE" <<EOF
model_provider = "abingo_codex"
model = "$SAFE_MODEL"
review_model = "$SAFE_MODEL"
model_reasoning_effort = "high"
disable_response_storage = true
network_access = "enabled"
model_context_window = 262144
model_auto_compact_token_limit = 242000

[model_providers.abingo_codex]
name = "Abingo Codex"
base_url = "$SAFE_BASE_URL"
wire_api = "responses"
requires_openai_auth = true
EOF

cat > "$AUTH_FILE" <<EOF
{
  "OPENAI_API_KEY": "$SAFE_API_KEY"
}
EOF

chmod 600 "$CONFIG_FILE" "$AUTH_FILE" 2>/dev/null || true

say ""
say "=================================================="
say "          $APP_NAME Setup Complete"
say "=================================================="
say "Config file: $CONFIG_FILE"
say "Auth file: $AUTH_FILE"
say "Service URL: $BASE_URL"
say "Default model: $MODEL"
say ""

say "Testing service connection..."

if command -v curl >/dev/null 2>&1; then
  if curl -fsS "$BASE_URL/models" -H "Authorization: Bearer $API_KEY" >/dev/null 2>&1; then
    say "Connection test passed."
  else
    say "Connection test failed, but the configuration has been written."
    say "Please check your network, key, or service status."
  fi
else
  say "curl was not found. Skipping connection test."
fi

say ""

if command -v codex >/dev/null 2>&1; then
  say "Codex CLI detected. You can now run:"
  say "  codex"
else
  say "The 'codex' command was not found."
  say "The Abingo Codex configuration has been written, but Codex CLI is required to run 'codex'."
  say "If Codex CLI is already installed, close this terminal and open a new one."
fi

say ""
say "Done."
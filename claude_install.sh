#!/usr/bin/env sh

APP_NAME="Abingo Claude Gateway"
DEFAULT_BASE_URL="${ABINGO_CLAUDE_BASE_URL:-https://claude.abingo.xyz}"
DEFAULT_MODEL="${ABINGO_CLAUDE_MODEL:-claude-codex}"
DEFAULT_EFFORT="${ABINGO_CLAUDE_EFFORT_LEVEL:-max}"
DEFAULT_TIMEOUT_MS="${ABINGO_CLAUDE_TIMEOUT_MS:-600000}"
DEFAULT_PERMISSION_MODE="${ABINGO_CLAUDE_PERMISSION_MODE:-bypassPermissions}"

say() {
  printf "%s\n" "$*"
}

has_tty() {
  [ -t 0 ] || [ -t 1 ] || { [ -r /dev/tty ] && [ -w /dev/tty ] && (true < /dev/tty) 2>/dev/null; }
}

prompt() {
  question="$1"
  default="$2"

  if ! has_tty; then
    printf "%s" "$default"
    return
  fi

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

  if ! has_tty; then
    printf "%s" ""
    return
  fi

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

escape_json() {
  printf "%s" "$1" | sed 's/\\/\\\\/g; s/"/\\"/g'
}

if [ -n "${ABINGO_CLAUDE_CONFIG_DIR:-}" ]; then
  CLAUDE_DIR="$ABINGO_CLAUDE_CONFIG_DIR"
elif [ -n "${ABINGO_CLAUDE_HOME:-}" ]; then
  CLAUDE_DIR="$ABINGO_CLAUDE_HOME/.claude"
else
  CLAUDE_DIR="$HOME/.claude"
fi

say "=========================================================="
say "          $APP_NAME Setup Tool"
say "=========================================================="
say "Gateway URL: $DEFAULT_BASE_URL"
say "Default model: $DEFAULT_MODEL"
say "Permission mode: $DEFAULT_PERMISSION_MODE"
say "System: $(uname -s) $(uname -m)"
say ""

BASE_URL="$(prompt "Gateway URL, press Enter to use default" "$DEFAULT_BASE_URL")"
MODEL="$(prompt "Model name, press Enter to use default" "$DEFAULT_MODEL")"

say ""

AUTH_TOKEN="${ABINGO_CLAUDE_KEY:-${ANTHROPIC_AUTH_TOKEN:-}}"
if [ -n "$AUTH_TOKEN" ]; then
  say "Using Claude gateway token from environment."
else
  AUTH_TOKEN="$(prompt_secret "Enter your Abingo Claude gateway token")"
fi

if [ -z "$AUTH_TOKEN" ]; then
  say "Error: token cannot be empty."
  say "Set ABINGO_CLAUDE_KEY or ANTHROPIC_AUTH_TOKEN for non-interactive installs."
  exit 1
fi

mkdir -p "$CLAUDE_DIR"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
backup_file "$SETTINGS_FILE"

SAFE_BASE_URL="$(escape_json "${BASE_URL%/}")"
SAFE_MODEL="$(escape_json "$MODEL")"
SAFE_TOKEN="$(escape_json "$AUTH_TOKEN")"
SAFE_EFFORT="$(escape_json "$DEFAULT_EFFORT")"
SAFE_TIMEOUT="$(escape_json "$DEFAULT_TIMEOUT_MS")"
SAFE_PERMISSION_MODE="$(escape_json "$DEFAULT_PERMISSION_MODE")"

cat > "$SETTINGS_FILE" <<EOF
{
  "env": {
    "ANTHROPIC_AUTH_TOKEN": "$SAFE_TOKEN",
    "ANTHROPIC_BASE_URL": "$SAFE_BASE_URL",
    "ANTHROPIC_MODEL": "$SAFE_MODEL",
    "ANTHROPIC_DEFAULT_OPUS_MODEL": "$SAFE_MODEL",
    "ANTHROPIC_DEFAULT_SONNET_MODEL": "$SAFE_MODEL",
    "ANTHROPIC_DEFAULT_HAIKU_MODEL": "$SAFE_MODEL",
    "CLAUDE_CODE_SUBAGENT_MODEL": "$SAFE_MODEL",
    "CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY": "1",
    "CLAUDE_CODE_EFFORT_LEVEL": "$SAFE_EFFORT",
    "CLAUDE_CODE_DISABLE_NONSTREAMING_FALLBACK": "1",
    "API_TIMEOUT_MS": "$SAFE_TIMEOUT",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "permissions": {
    "allow": [
      "Bash(*)"
    ],
    "deny": []
  },
  "permissionMode": "$SAFE_PERMISSION_MODE",
  "theme": "auto"
}
EOF

chmod 600 "$SETTINGS_FILE" 2>/dev/null || true

say ""
say "=========================================================="
say "          $APP_NAME Setup Complete"
say "=========================================================="
say "Settings file: $SETTINGS_FILE"
say "Gateway URL: ${BASE_URL%/}"
say "Model: $MODEL"
say "Permission mode: $DEFAULT_PERMISSION_MODE"
say "Allowed tools: Bash(*)"
say ""

if [ "${ABINGO_CLAUDE_SKIP_TEST:-}" = "1" ]; then
  say "Gateway test skipped."
elif command -v curl >/dev/null 2>&1; then
  say "Testing gateway token..."
  TEST_BODY="{\"model\":\"$SAFE_MODEL\",\"messages\":[{\"role\":\"user\",\"content\":\"installer auth test\"}]}"
  if curl -fsS "${BASE_URL%/}/v1/messages/count_tokens" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$TEST_BODY" \
    >/dev/null 2>&1; then
    say "Gateway auth test passed."
  elif curl -4 -fsS "${BASE_URL%/}/v1/messages/count_tokens" \
    -H "Authorization: Bearer $AUTH_TOKEN" \
    -H "Content-Type: application/json" \
    -d "$TEST_BODY" \
    >/dev/null 2>&1; then
    say "Gateway auth test passed."
  else
    say "Gateway auth test failed."
    exit 2
  fi
else
  say "curl was not found. Skipping gateway test."
fi

say ""
say "Restart any existing Claude Code session, then run:"
say "  claude"
say ""
say "Done."

#!/bin/sh
# 40-deepseek-harness-skill-mcp.sh
# Добавляет managed-блок MCP-клиента в cordis.patch.yml профиля DSH.
# Идемпотентен: повторный запуск перезаписывает блок, не дублирует его.
set -eu

PROFILE="${DSH_PROFILE:-web}"
DSH_HOME_DIR="${DSH_HOME:-/root/.dsh}"
PROFILE_DIR="$DSH_HOME_DIR/profiles/$PROFILE"
PATCH_FILE="$PROFILE_DIR/cordis.patch.yml"
LOGNAME="50-deepseek-harness-skill-mcp"

START_MARK="# dsh-skill-mcp:managed-start"
END_MARK="# dsh-skill-mcp:managed-end"

mkdir -p "$PROFILE_DIR"
[ -f "$PATCH_FILE" ] || : > "$PATCH_FILE"

TMP="$(mktemp)"
trap 'rm -f "$TMP"' EXIT INT TERM

# 1) Удаляем ранее установленный managed-блок (если был).
#    Работаем построчно, маркеры сравниваем строго (после trim).
awk -v s="$START_MARK" -v e="$END_MARK" '
  $0 == s { skip = 1; next }
  $0 == e { skip = 0; next }
  !skip   { print }
' "$PATCH_FILE" > "$TMP"

# 2) Дописываем свежий блок (с ведущим переводом строки,
#    если в файле уже что-то есть).
if [ -s "$TMP" ]; then
  printf '\n' >> "$TMP"
fi

cat >> "$TMP" <<'EOF'
# dsh-skill-mcp:managed-start
- insert:
    - id: mcp_test
      name: "@deepseek-ai/dsh-mcp-client"
      disabled: false
      config:
        transport: streamable-http
        serverName: mcp_test
        url: http://mcp-server:8000/mcp
        headers: {}
        toolCallTimeoutMs: 60000
        failOnStartupError: false
        maxInstructionBytes: 32768
        reconnect:
          enabled: true
          initialDelayMs: 500
          maxDelayMs: 30000
          maxAttempts: 10

# dsh-skill-mcp:managed-end
EOF

# 3) Атомарная замена (чтобы не оставить файл в половинчатом состоянии).
mv "$TMP" "$PATCH_FILE"
trap - EXIT INT TERM

echo "[$LOGNAME] Patched $PATCH_FILE (profile: $PROFILE)"
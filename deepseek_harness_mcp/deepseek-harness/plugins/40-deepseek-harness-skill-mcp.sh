#!/bin/sh
set -eu

PLUGIN="@civilization/deepseek-harness-skill-mcp"
PROFILE="${DSH_PROFILE:-web}"
MARKER_DIR="${DSH_HOME:-/root/.dsh}/profiles/${PROFILE}/node_modules/@civilization"
LOGNAME="40-@civilization/deepseek-harness-skill-mcp"

# Идемпотентность: если плагин уже стоит — выходим.
if [ -d "$MARKER_DIR/deepseek-harness-skill-mcp" ]; then
  echo "[$LOGNAME] $PLUGIN already installed. Skipping."
  exit 0
fi

echo "[$LOGNAME] Installing $PLUGIN into profile '$PROFILE'..."
dsh plugin --profile "$PROFILE" add "$PLUGIN"

echo "[$LOGNAME] Done."
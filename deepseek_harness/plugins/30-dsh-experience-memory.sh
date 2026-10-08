dsh plugin --profile web add 
dsh plugin --profile "$PROFILE" add "$PLUGIN"


#!/bin/sh
# 10-kilo.sh — устанавливает плагин Kilo Gateway (@huanx/kilo-zen2dsh)
set -eu

PLUGIN="@marquez807/dsh-experience-memory"
PROFILE="${DSH_PROFILE:-web}"
MARKER_DIR="${DSH_HOME:-/root/.dsh}/profiles/${PROFILE}/node_modules/@marquez807"

# Идемпотентность: если плагин уже стоит — выходим.
if [ -d "$MARKER_DIR/dsh-experience-memory" ]; then
  echo "[30-dsh-experience-memory"] $PLUGIN already installed. Skipping."
  exit 0
fi

echo "[30-dsh-experience-memory] Installing $PLUGIN into profile '$PROFILE'..."
dsh plugin --profile "$PROFILE" add "$PLUGIN"

echo "[dsh-experience-memory] Done."
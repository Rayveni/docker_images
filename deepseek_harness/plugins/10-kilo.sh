#!/bin/sh
# 10-kilo.sh — устанавливает плагин Kilo Gateway (@huanx/kilo-zen2dsh)
set -eu

PLUGIN="@huanx/kilo-zen2dsh"
PROFILE="${DSH_PROFILE:-web}"
MARKER_DIR="${DSH_HOME:-/root/.dsh}/profiles/${PROFILE}/node_modules/@huanx"

# Идемпотентность: если плагин уже стоит — выходим.
if [ -d "$MARKER_DIR/kilo-zen2dsh" ]; then
  echo "[10-kilo] $PLUGIN already installed. Skipping."
  exit 0
fi

echo "[10-kilo] Installing $PLUGIN into profile '$PROFILE'..."
dsh plugin --profile "$PROFILE" add "$PLUGIN"

echo "[10-kilo] Done."
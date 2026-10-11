#!/bin/sh
set -eu

PLUGIN="dsh-workspace-scope"
PROFILE="${DSH_PROFILE:-web}"
MARKER_DIR="${DSH_HOME:-/root/.dsh}/profiles/${PROFILE}/node_modules"
LOGNAME="30-dsh-workspace-scope"

# Идемпотентность: если плагин уже стоит — выходим.
if [ -d "$MARKER_DIR/$PLUGIN" ]; then
  echo "[$LOGNAME] $PLUGIN already installed. Skipping."
  exit 0
fi

echo "[$LOGNAME] Installing $PLUGIN into profile '$PROFILE'..."
dsh plugin --profile "$PROFILE" add "$PLUGIN"

echo "[$LOGNAME] Done."
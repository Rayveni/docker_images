#!/bin/sh
# install_plugins.sh — последовательно запускает все *.sh из своей папки,
# кроме самого себя. Порядок — по имени файла (используйте префиксы 10-, 20-...).
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SELF="$(basename "$0")"

echo "[install_plugins] Looking for scripts in: $SCRIPT_DIR"

# Собираем список скриптов, исключая сам оркестратор, сортируем по имени.
SCRIPTS="$(find "$SCRIPT_DIR" -maxdepth 1 -type f -name '*.sh' \
  ! -name "$SELF" | sort)"

if [ -z "$SCRIPTS" ]; then
  echo "[install_plugins] No plugin scripts found. Nothing to do."
  exit 0
fi

FAILED=""

# Inside your install_plugins.sh script, alter your installation commands to:
pnpm install --allow-build=@google/genai --allow-build=protobufjs




for script in $SCRIPTS; do
  name="$(basename "$script")"
  echo ""
  echo "[install_plugins] ============================================"
  echo "[install_plugins] Running: $name"
  echo "[install_plugins] ============================================"

  if sh "$script"; then
    echo "[install_plugins] ✓ $name completed"
  else
    echo "[install_plugins] ✗ $name FAILED (continuing with next)"
    FAILED="$FAILED $name"
  fi
done

echo ""
if [ -n "$FAILED" ]; then
  echo "[install_plugins] Finished with errors in:$FAILED"
  exit 1
fi

echo "[install_plugins] All plugins installed successfully."
exit 0
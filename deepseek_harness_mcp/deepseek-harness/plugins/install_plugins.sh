#!/bin/sh
set -eu

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SELF="$(basename "$0")"

echo "[install_plugins] Looking for scripts in: $SCRIPT_DIR"

LIST_FILE="$(mktemp)"
FAILED_FILE="$(mktemp)"
trap 'rm -f "$LIST_FILE" "$FAILED_FILE"' EXIT INT TERM

# Собираем список скриптов, исключая себя, сортируем по имени.
find "$SCRIPT_DIR" -maxdepth 1 -type f -name '*.sh' ! -name "$SELF" \
  | LC_ALL=C sort > "$LIST_FILE"

if [ ! -s "$LIST_FILE" ]; then
  echo "[install_plugins] No plugin scripts found. Nothing to do."
  exit 0
fi

# Опциональный pnpm-шаг — один раз до цикла
pnpm install --allow-build=@google/genai --allow-build=protobufjs

# while + IFS= read -r — корректно работает с пробелами в именах.
while IFS= read -r script; do
  name="$(basename "$script")"
  echo ""
  echo "[install_plugins] ============================================"
  echo "[install_plugins] Running: $name"
  echo "[install_plugins] ============================================"

  if sh "$script"; then
    echo "[install_plugins] ✓ $name completed"
  else
    echo "[install_plugins] ✗ $name FAILED (continuing with next)"
    printf '%s\n' "$name" >> "$FAILED_FILE"
  fi
done < "$LIST_FILE"

echo ""
if [ -s "$FAILED_FILE" ]; then
  echo "[install_plugins] Finished with errors in:"
  while IFS= read -r n; do
    echo "  - $n"
  done < "$FAILED_FILE"
  exit 1
fi

echo "[install_plugins] All plugins installed successfully."
exit 0
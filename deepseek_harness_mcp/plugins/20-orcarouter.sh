#!/bin/sh
set -eu

DSH_HOME="${DSH_HOME:-/root/.dsh}"
SETTINGS="$DSH_HOME/settings.yaml"

if [ -z "${ORCAROUTER_API_KEY:-}" ]; then
    echo "[20-orcarouter] ORCAROUTER_API_KEY не задан, пропуск"
    exit 0
fi

mkdir -p "$DSH_HOME"
[ -f "$SETTINGS" ] || echo "{}" > "$SETTINGS"

SETTINGS="$SETTINGS" node -e '
const fs = require("fs");
const YAML = require("/opt/dsh-tools/node_modules/yaml");

const file = process.env.SETTINGS;
const doc  = YAML.parse(fs.readFileSync(file, "utf8") || "{}") || {};

doc["llm-pi-ai"] ??= {};
doc["llm-pi-ai"].providers ??= {};
doc["llm-pi-ai"].providers.orcarouter = {
  apiKeyEnv: "ORCAROUTER_API_KEY",
  api: "openai-completions",
  baseURL: "https://api.orcarouter.ai/v1",
  displayName: "OrcaRouter",
  models: [
    { id: "deepseek/deepseek-chat" },
    { id: "openai/gpt-4o-mini" },
    { id: "anthropic/claude-sonnet-4.6" },
  ],
};

fs.writeFileSync(file, YAML.stringify(doc));
'

echo "[20-orcarouter] провайдер добавлен"
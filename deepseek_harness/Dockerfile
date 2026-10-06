FROM smanx/deepseek-harness:latest

RUN npm install -g pnpm

# Глобальный конфиг pnpm — лечит ERR_PNPM_IGNORED_BUILDS во ВНУТРЕННЕМ pnpm,
# который `dsh plugin install` запускает сам. Env-переменные до него не доходят,
# а этот файл читается любым pnpm-вызовом.
RUN mkdir -p /root/.config/pnpm \
 && printf '%s\n' \
    'strictDepBuilds: false' \
    'dangerouslyAllowAllBuilds: true' \
    > /root/.config/pnpm/config.yaml

COPY plugins/ /tmp/plugins/
COPY pnpm-workspace.yaml /tmp/plugins/pnpm-workspace.yaml
RUN chmod +x /tmp/plugins/*.sh

# Обёртка вокруг РЕАЛЬНОГО entrypoint (/app/entrypoint.sh):
# ставит плагины, потом отдаёт управление родному скрипту.
RUN mv /app/entrypoint.sh /app/entrypoint.orig.sh \
 && printf '%s\n' \
    '#!/bin/sh' \
    'set -u' \
    'export DSH_PROFILE="${DSH_PROFILE:-web}"' \
    'export CI=true' \
    '' \
    'if [ -d /tmp/plugins ]; then' \
    '    (cd /tmp/plugins && sh ./install_plugins.sh) || echo "[entrypoint] install failed, continuing" >&2' \
    'fi' \
    '' \
    'exec /app/entrypoint.orig.sh "$@"' \
    > /app/entrypoint.sh \
 && chmod +x /app/entrypoint.sh

# ENTRYPOINT и CMD базового образа не трогаем —
# они уже указывают на /app/entrypoint.sh (наш wrapper).
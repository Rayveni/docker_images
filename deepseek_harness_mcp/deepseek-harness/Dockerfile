FROM smanx/deepseek-harness:latest

# pnpm + глобальный конфиг + yaml-библиотека для правки settings.yaml
RUN npm install -g pnpm \
 && mkdir -p /opt/dsh-tools \
 && cd /opt/dsh-tools \
 && npm init -y >/dev/null \
 && npm install --omit=dev yaml@2 >/dev/null \
 && mkdir -p /root/.config/pnpm \
 && printf 'dangerouslyAllowAllBuilds: true\nstrictDepBuilds: false\n' \
    > /root/.config/pnpm/config.yaml

COPY plugins/ /tmp/plugins/
RUN chmod +x /tmp/plugins/*.sh

RUN mv /app/entrypoint.sh /app/entrypoint.orig.sh \
 && printf '#!/bin/sh\nset -u\n(cd /tmp/plugins && sh ./install_plugins.sh) || true\nexec /app/entrypoint.orig.sh "$@"\n' \
    > /app/entrypoint.sh \
 && chmod +x /app/entrypoint.sh
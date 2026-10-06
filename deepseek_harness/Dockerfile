FROM smanx/deepseek-harness:latest

RUN npm install -g pnpm


COPY plugins/ /tmp/plugins/
COPY pnpm-workspace.yaml /tmp/plugins/pnpm-workspace.yaml
RUN chmod +x /tmp/plugins/*.sh

# ENTRYPOINT и CMD НЕ переопределяем —
# используются дефолтные от базового образа (там поднимается proxy+token).
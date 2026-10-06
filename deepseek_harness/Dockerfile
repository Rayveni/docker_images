FROM smanx/deepseek-harness:latest

# 1. Устанавливаем pnpm (если ещё не установлен)
RUN npm install -g pnpm

# 2. Копируем файл с разрешениями для сборок в директорию профиля DSH
#    Это ключевой шаг: pnpm будет читать этот файл при установке плагинов.
COPY pnpm-workspace.yaml /root/.dsh/profiles/web/pnpm-workspace.yaml

# 3. Копируем и запускаем скрипт установки всех плагинов
COPY plugins/ /tmp/plugins/

RUN chmod +x /tmp/plugins/install_plugins.sh && \
    bash /tmp/plugins/install_plugins.sh && \
    rm -rf /tmp/plugins
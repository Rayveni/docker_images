# --- Слой сборки зависимостей (Builder) ---
FROM python:3.11-slim-bookworm AS builder

WORKDIR /build

# Установка системных зависимостей для компиляции wheels
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    git \
    && rm -rf /var/lib/apt/lists/*

# Копируем описание зависимостей
COPY requirements.txt .

# Компиляция жестко зафиксированного requirements.txt и сборка wheel-пакетов
RUN pip install --no-cache-dir pip-tools && \
    pip-compile --output-file=requirements.in requirements.txt && \
    pip wheel --no-cache-dir --wheel-dir=/build/wheels -r requirements.in \
    "gigaam[torch] @ git+https://github.com/salute-developers/GigaAM"

# --- Финальный слой выполнения (Runtime) ---
FROM python:3.11-slim-bookworm

ENV TZ=Europe/Moscow \
    PYTHONUNBUFFERED=1

# Установка системных библиотек для работы с аудио
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    libsndfile1 \
    ffmpeg \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Переносим скомпилированные пакеты из builder-слоя
COPY --from=builder /build/wheels /wheels
# Copy only the generated requirements.txt from the builder stage
COPY --from=builder /build/requirements.in .

# Установка Python-пакетов из локальных wheel-файлов без доступа к сети
RUN pip install --no-cache-dir --no-index --find-links=/wheels /wheels/*.whl && \
    rm -rf /wheels

# Копируем код приложения (максимальное кеширование слоев)
COPY main.py .

ENTRYPOINT ["python", "main.py"]
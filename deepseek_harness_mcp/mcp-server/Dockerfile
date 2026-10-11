FROM python:3.12-slim

# Устанавливаем рабочую директорию
WORKDIR /app

# Устанавливаем FastMCP
RUN pip install --no-cache-dir fastmcp

# Копируем код сервера
COPY server.py .
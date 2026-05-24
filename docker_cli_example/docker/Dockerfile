# --- Build Stage (Builder) ---
FROM python:3.11-slim-bookworm as builder

# Install build dependencies (needed for compiling certain python wheels)
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    && rm -rf /var/lib/apt/lists/*

# Copy input requirements and compile them into a locked requirements.txt
COPY requirements.txt .
RUN pip install --no-cache-dir pip-tools && \
    pip-compile --output-file requirements.in requirements.txt

# --- Final Runtime Stage ---
FROM python:3.11-slim-bookworm

# Set timezone and install runtime system libraries in a single layer
ENV TZ=Europe/Moscow
RUN apt-get update && apt-get install -y --no-install-recommends \
    tzdata \
    libsndfile1 \
    ffmpeg \
    && ln -fs /usr/share/zoneinfo/$TZ /etc/localtime \
    && dpkg-reconfigure -f noninteractive tzdata \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy only the generated requirements.txt from the builder stage
COPY --from=builder /requirements.in .

# Install python dependencies without storing cache to save space
RUN pip install --no-cache-dir -r requirements.in

# Copy application code last to maximize Docker layer caching
COPY main.py .

ENTRYPOINT ["python", "main.py"]
FROM python:3.9.16-slim-bullseye

ENV PYTHONDONTWRITEBYTECODE 1
ENV PYTHONUNBUFFERED 1


COPY app/requirements.txt /
RUN pip3 install --no-cache-dir -r /requirements.txt

WORKDIR /app/app


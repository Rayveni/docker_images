@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Параметры конфигурации
set "model_name=v3_e2e_rnnt"
set "folder_path=E:\notebook" 
set "compose_path=E:\git\docker_images\giga_cli\docker-compose.yml"
set "audio_file_path=Recording 20260521141610.m4a"

:: Формируем чистый путь к целевой папке (исправлен синтаксис переменных)
set "target=%folder_path%\transcribed"
echo Целевая папка: %target%

:: Создаем папку transcribed, если она еще не существует
if not exist "%target%" mkdir "%target%"

:: Переходим в исходную папку
cd /d "%folder_path%"

:: Запуск Docker с правильным экранированием путей
docker compose -f "%compose_path%" run --rm -v "%cd%":/app/in gigaam --audio_file_path="%audio_file_path%" --diarization=1 --model="%model_name%" --requirements=1

pause

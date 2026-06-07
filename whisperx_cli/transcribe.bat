@echo off
chcp 65001 >nul
setlocal enabledelayedexpansion

:: Инициализация цветов ANSI
for /F "tokens=1,2 delims=#" %%a in ('"prompt #$H#$E# & echo on & for %%b in (1) do rem"') do set "ESC=%%b"

:: Цвета текста
set "RED=%ESC%[31m"
set "GREEN=%ESC%[32m"
set "YELLOW=%ESC%[33m"
set "BLUE=%ESC%[34m"
set "CYAN=%ESC%[36m"
set "RESET=%ESC%[0m"

set "model_name=large-v3"
:: set "model_name=antony66/whisper-large-v3-russian"

echo Passed params:  %1
echo Passed params2:  %2

:: Формируем чистый путь к целевой папке
set "target=%~1\transcribed"
echo %YELLOW%Целевая папка:%RESET% %target%

:: Создаем папку transcribed, если она еще не существует
if not exist "%target%" mkdir "%target%"

:: Переходим в исходную папку
cd /d "%~1"

:: Подсчет общего количества файлов
set "total=0"
for %%F in (*.m4a) do set /a total+=1

:: Если файлов нет, выводим сообщение и выходим
if %total%==0 (
    echo %RED%Файлы .m4a не найдены в этой папке.%RESET%
    pause
    exit /b
)

set "current=0"

echo %YELLOW%Reading files in:%RESET% %~1
echo ---------------------------------------

:: Цикл по всем файлам
for %%F in (*.m4a) do (
    :: Увеличиваем счетчик текущего файла (ВАЖНО!)
    set /a current+=1

    :: Вычисляем процент и количество делений шкалы
    set /a "pct=(current * 100) / total"
    set /a "bars=pct / 10"
    
    :: Рисуем шкалу прогресса
    set "progress=["
    for /l %%i in (1,1,10) do (
        if %%i leq !bars! (set "progress=!progress!█") else (set "progress=!progress!░")
    )
    set "progress=!progress!] !pct!%%"
    
    :: Вывод прогресса и имени файла
    echo.
    echo %GREEN%!progress!%RESET% Обработка файла !current! из %total%
    echo %CYAN%Файл:%RESET% "%%~nxF"
    echo ---------------------------------------

    :: Запуск Docker для текущего файла (используем %~2 без лишних кавычек)
    docker compose -f "%~2" run --rm -v "%cd%":/app/in whisperx --audio_file_path="%%~nxF" --diarization=1 --compute=accurate --model="%model_name%"
    
    :: Перемещение обработанного файла
    move "%%~nxF" "%target%\" >nul
)

echo.
echo %GREEN%[ГОТОВО]%RESET% Все файлы успешно обработаны и перемещены!
pause
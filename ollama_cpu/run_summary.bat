@echo off
chcp 65001 > nul

:: Настройки скрипта
set "TEXT_FILE=meeting_transcript.txt"
set "MODEL_NAME=qwen3.5:9b"
set "PROMPT_PREFIX=Summarize this text: "
set "OUTPUT_FILE=summary.txt"

:: Проверка наличия исходного файла
if not exist "%TEXT_FILE%" (
    echo Ошибка: Файл %TEXT_FILE% не найден!
    pause
    exit /b
)

echo Отправка запроса в Ollama (%MODEL_NAME%)... Пожалуйста, подождите...

:: Запуск PowerShell для отправки запроса, замера времени и сохранения результата
powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "$stopwatch = [System.Diagnostics.Stopwatch]::StartNew();" ^
    "$text = Get-Content -Raw -Path '%TEXT_FILE%' -Encoding UTF8;" ^
    "$prompt = '%PROMPT_PREFIX%' + $text;" ^
    "$body = @{ model = '%MODEL_NAME%'; prompt = $prompt; stream = $false } | ConvertTo-Json -Depth 10;" ^
    "$response = Invoke-RestMethod -Uri 'http://localhost:11434/api/generate' -Method Post -Body $body -ContentType 'application/json; charset=utf-8';" ^
    "$stopwatch.Stop();" ^
    "$elapsed = $stopwatch.Elapsed;" ^
    "$timeStr = [string]::Format('{0:00}:{1:00}:{2:00}.{3:00}', $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds, $elapsed.Milliseconds / 10);" ^
    "Set-Content -Path '%OUTPUT_FILE%' -Value $response.response -Encoding UTF8;" ^
    "Write-Host '--------------------------------------------------';" ^
    "Write-Host 'Успешно! Результат сохранен в:' '%OUTPUT_FILE%';" ^
    "Write-Host 'Время выполнения:' $timeStr;" ^
    "Write-Host '--------------------------------------------------';"

pause

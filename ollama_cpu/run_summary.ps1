param (
    [string]$TextFile,
    [string]$OutputFile

)


# Принудительно настраиваем консоль PowerShell на UTF-8
[console]::InputEncoding = [System.Text.Encoding]::UTF8
[console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = [System.Text.Encoding]::UTF8

# --- НАСТРОЙКИ СКРИПТА ---
$ModelName    = "qwen3.5:9b"
$PromptPrefix = "Summarize this text: "
#$OutputFile   = "summary.txt"
$DockerImage  = "ollama/ollama"
# -------------------------

# Проверка наличия исходного файла
if (-not (Test-Path -Path $TextFile)) {
    Write-Error "Error: File $TextFile not found!"
    Read-Host "Press Enter to exit..."
    exit
}

# [1/4] Проверка Docker
Write-Host "[1/4] Docker check..." -ForegroundColor Cyan
docker ps > $null 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Error "Error: Docker Desktop is not running! Please start it and try again."
    Read-Host "Press Enter to exit..."
    exit
}

# Поиск существующего контейнера Ollama
$containerName = docker ps -a --filter "ancestor=$DockerImage" --format "{{.Names}}" | Select-Object -First 1

if ([string]::IsNullOrEmpty($containerName)) {
    $containerName = "ollama_auto"
    Write-Host "Container not found. Creating container '$containerName'..." -ForegroundColor Yellow
    docker run -d -v ollama:/root/.ollama -p 11434:11434 --name ollama_auto $DockerImage > $null
} else {
    Write-Host "Found existing container. Starting container '$containerName'..." -ForegroundColor Green
    docker start $containerName > $null
}

# [2/4] Ожидание запуска API Ollama
Write-Host "[2/4] Waiting for Ollama API to start..." -ForegroundColor Cyan
while ($true) {
    try {
        $check = Invoke-WebRequest -Uri "http://localhost:11434/" -Method Get -TimeoutSec 1 > $null
        break
    } catch {
        Start-Sleep -Seconds 2
    }
}

# [3/4] Отправка запроса и замер времени
Write-Host "[3/4] Sending request to Ollama ($ModelName)... Please wait..." -ForegroundColor Cyan

$stopwatch = [System.Diagnostics.Stopwatch]::StartNew()

try {
    $text = Get-Content -Raw -Path $TextFile -Encoding UTF8
    $prompt = $PromptPrefix + $text
    $body = @{ 
        model  = $ModelName
        prompt = $prompt
        stream = $false 
    } | ConvertTo-Json -Depth 10

    # Отправка API-запроса (таймаут 10 минут для больших текстов)
    $response = Invoke-RestMethod -Uri "http://localhost:11434/api/generate" -Method Post -Body $body -ContentType "application/json; charset=utf-8" -TimeoutSec 600
    
    $stopwatch.Stop()
    $elapsed = $stopwatch.Elapsed
    $timeStr = [string]::Format("{0:00}:{1:00}:{2:00}.{3:00}", $elapsed.Hours, $elapsed.Minutes, $elapsed.Seconds, $elapsed.Milliseconds / 10)

    # Сохранение результата
    Set-Content -Path $OutputFile -Value $response.response -Encoding UTF8

        Write-Host "--------------------------------------------------" -ForegroundColor Green
        Write-Host "Success! Result saved to: $OutputFile" -ForegroundColor Green
        Write-Host "Execution time: $timeStr" -ForegroundColor Green
        Write-Host "--------------------------------------------------" -ForegroundColor Green
} 
catch {
    $stopwatch.Stop()
    Write-Error "Request execution error.Check if  $ModelName. downloaded"
    Write-Error $_.Exception.Message
}

# [4/4] Остановка контейнера Docker
Write-Host "[4/4] Stopping container '$containerName'..." -ForegroundColor Cyan
docker stop $containerName > $null
Write-Host "Container stopped." -ForegroundColor Yellow

Read-Host "Press Enter to finish..."

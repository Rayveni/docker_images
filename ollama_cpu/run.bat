@echo off
:: Переключаем кодировку консоли Windows на UTF-8
chcp 65001 > nul
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0run_summary.ps1"

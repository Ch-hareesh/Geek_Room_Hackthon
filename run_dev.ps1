param()
# run_dev.ps1 -- Local Development Launcher (Windows)
# Usage: powershell -ExecutionPolicy Bypass -File run_dev.ps1

# Activate venv
Write-Host '-- Activating virtual environment...' -ForegroundColor Cyan
. .\venv\Scripts\Activate.ps1

# Copy .env.example to .env if .env is missing
if (-Not (Test-Path '.env')) {
    Copy-Item '.env.example' '.env'
    Write-Host 'WARNING: .env created from .env.example -- add your API keys!' -ForegroundColor Yellow
}

Write-Host ''
Write-Host '=======================================' -ForegroundColor Green
Write-Host '  AI Financial Research Agent (Dev)  ' -ForegroundColor Green
Write-Host '=======================================' -ForegroundColor Green
Write-Host ''

$root = $PWD.Path

# Start FastAPI backend in a new window
Write-Host '>> Starting FastAPI backend on http://127.0.0.1:8000 ...' -ForegroundColor Blue
Start-Process powershell -ArgumentList '-NoExit', '-Command', "cd '$root'; .\venv\Scripts\Activate.ps1; uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 --reload"

Start-Sleep -Seconds 2

# Start Next.js frontend dev server in a new window
Write-Host '>> Starting Next.js frontend on http://localhost:3000 ...' -ForegroundColor Blue
Start-Process powershell -ArgumentList '-NoExit', '-Command', "cd '$root\frontend'; npm run dev"

Write-Host ''
Write-Host 'Both services are starting in separate windows.' -ForegroundColor Green
Write-Host '  Backend  --> http://127.0.0.1:8000'
Write-Host '  Frontend --> http://localhost:3000'
Write-Host ''
Write-Host 'Close those windows (or press Ctrl+C) to stop the services.'

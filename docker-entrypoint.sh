#!/bin/sh
# docker-entrypoint.sh
set -e

echo "========================================"
echo "  🏦 AI Financial Research Agent"
echo "========================================"

# 1. Start FastAPI backend on INTERNAL localhost:8000
# We use 127.0.0.1 so it is only accessible by Next.js (via proxy)
echo "▶  Starting FastAPI backend on port 8000..."
cd /app
uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 &
BACKEND_PID=$!

# 2. Start Next.js frontend on the PUBLIC Render PORT
# Render automatically sets the $PORT environment variable (e.g., 10000)
CURRENT_PORT=${PORT:-3000}
echo "▶  Starting Next.js frontend on port $CURRENT_PORT..."
cd /app/frontend
npx next start --hostname 0.0.0.0 --port $CURRENT_PORT &
FRONTEND_PID=$!

echo "========================================"
echo "  ✅  Services started"
echo "  Backend (Internal) → http://127.0.0.1:8000"
echo "  Frontend (Public)  → http://0.0.0.0:$CURRENT_PORT"
echo "========================================"

# Wait for either process to exit
wait $BACKEND_PID $FRONTEND_PID
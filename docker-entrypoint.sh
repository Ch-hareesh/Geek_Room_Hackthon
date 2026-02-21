#!/bin/sh
# docker-entrypoint.sh
# Starts both the FastAPI backend and the Next.js frontend server.
# Both processes run concurrently; the script waits for either to exit.

set -e

echo "========================================"
echo "  🏦 AI Financial Research Agent"
echo "========================================"

# Start FastAPI backend (port 8000)
echo "▶  Starting FastAPI backend on port 8000..."
cd /app
uvicorn backend.app.main:app --host 0.0.0.0 --port 8000 &
BACKEND_PID=$!

# Start Next.js frontend (port 3000)
echo "▶  Starting Next.js frontend on port 3000..."
cd /app/frontend
npx next start --hostname 0.0.0.0 --port 3000 &
FRONTEND_PID=$!

echo "========================================"
echo "  ✅  Both services started"
echo "  API  →  http://localhost:8000"
echo "  Docs →  http://localhost:8000/docs"
echo "  UI   →  http://localhost:3000"
echo "========================================"

# Wait for either process to exit
wait $BACKEND_PID $FRONTEND_PID

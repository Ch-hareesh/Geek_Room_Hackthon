#!/bin/sh
# docker-entrypoint.sh
set -e

echo "========================================"
echo "  🏦 AI Financial Research Agent"
echo "========================================"

# 1. Start FastAPI backend on INTERNAL localhost:8000
# We bind to 127.0.0.1 so it is only reachable from Next.js via the rewrite proxy.
echo "▶  Starting FastAPI backend on port 8000..."
cd /app
uvicorn backend.app.main:app --host 127.0.0.1 --port 8000 &
BACKEND_PID=$!

# 2. Start Next.js frontend using the standalone server.js
# Render injects $PORT (e.g. 10000); default to 3000 for local Docker runs.
CURRENT_PORT=${PORT:-3000}
echo "▶  Starting Next.js frontend on port $CURRENT_PORT..."

# The standalone bundle was copied to /app/frontend/; server.js sits there.
cd /app/frontend
HOSTNAME=0.0.0.0 PORT=$CURRENT_PORT node server.js &
FRONTEND_PID=$!

echo "========================================"
echo "  ✅  Services started"
echo "  Backend (Internal) → http://127.0.0.1:8000"
echo "  Frontend (Public)  → http://0.0.0.0:$CURRENT_PORT"
echo "========================================"

# Wait for either process to exit (crash → container stops → Render restarts it)
wait $BACKEND_PID $FRONTEND_PID
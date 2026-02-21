# ============================================================
# Dockerfile — AI Financial Research Agent
#
# Multi-stage build:
#   Stage 1 (frontend-builder) — builds the Next.js static output
#   Stage 2 (backend)          — production Python image that serves
#                                the FastAPI API and the pre-built 
#                                Next.js app via a simple static server
#
# Usage:
#   docker build -t financial-agent .
#   docker run --env-file .env -p 8000:8000 -p 3000:3000 financial-agent
#
# Or use docker-compose (recommended):
#   docker compose up --build
# ============================================================


# ─────────────────────────────────────────────────────────────
# Stage 1 — Build the Next.js frontend
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS frontend-builder

WORKDIR /app/frontend

# Install dependencies first (cached layer)
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

# Copy source and build
COPY frontend/ ./
# Point the API rewrite at the backend container name (see docker-compose)
ENV NEXT_PUBLIC_API_URL=http://backend:8000
RUN npm run build


# ─────────────────────────────────────────────────────────────
# Stage 2 — Python backend + serve frontend
# ─────────────────────────────────────────────────────────────
FROM python:3.11-slim AS backend

# System dependencies required by torch / scipy / xgboost
RUN apt-get update && apt-get install -y --no-install-recommends \
        build-essential \
        libgomp1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# ── Python dependencies ──────────────────────────────────────
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# ── Application source code ──────────────────────────────────
COPY backend/ ./backend/
COPY .env.example .env.example

# ── Pre-trained model assets (optional) ─────────────────────
# Copy model files if they exist locally; they are excluded from
# .gitignore so must be present on the build host.
# If missing, the app starts in stub/demo mode automatically.
COPY backend/forecasting/ ./backend/forecasting/

# ── Frontend built output ────────────────────────────────────
COPY --from=frontend-builder /app/frontend/.next ./frontend/.next
#COPY --from=frontend-builder /app/frontend/public ./frontend/public
COPY --from=frontend-builder /app/frontend/node_modules ./frontend/node_modules
COPY --from=frontend-builder /app/frontend/package.json ./frontend/package.json

# ── Data directory ───────────────────────────────────────────
RUN mkdir -p /app/data

# ── Ports ────────────────────────────────────────────────────
# 8000 → FastAPI backend
# 3000 → Next.js frontend
EXPOSE 8000 3000

# ── Entrypoint ───────────────────────────────────────────────
# A small shell script starts both services; logs from both
# stream to stdout so `docker logs` captures everything.
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

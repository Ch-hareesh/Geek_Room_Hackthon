# ============================================================
# Dockerfile — AI Financial Research Agent
# ============================================================

# ─────────────────────────────────────────────────────────────
# Stage 1 — Build the Next.js frontend
# ─────────────────────────────────────────────────────────────
FROM node:20-alpine AS frontend-builder

WORKDIR /app/frontend

# Install dependencies
COPY frontend/package.json frontend/package-lock.json ./
RUN npm ci

# Copy source and build
COPY frontend/ ./
# Point the API rewrite at the internal backend
ENV NEXT_PUBLIC_API_URL=http://127.0.0.1:8000
RUN npm run build


# ─────────────────────────────────────────────────────────────
# Stage 2 — Python backend + Node.js Runtime
# ─────────────────────────────────────────────────────────────
FROM python:3.11-slim AS backend

# 1. Install System Deps + Node.js + npm
# We need Node.js/npm in the final image to run 'npx next start'
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    libgomp1 \
    curl \
    nodejs \
    npm \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2. Python dependencies
COPY requirements.txt ./
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir -r requirements.txt

# 3. Application source code
COPY backend/ ./backend/
COPY .env.example .env.example
# Copy model files if they exist locally
COPY backend/forecasting/ ./backend/forecasting/

# 4. Frontend built output
COPY --from=frontend-builder /app/frontend/.next ./frontend/.next
# COPY --from=frontend-builder /app/frontend/public ./frontend/public  <-- Keep commented if you don't have this folder
COPY --from=frontend-builder /app/frontend/node_modules ./frontend/node_modules
COPY --from=frontend-builder /app/frontend/package.json ./frontend/package.json

# 5. Data directory
RUN mkdir -p /app/data

# 6. Ports (Documentary only, Render controls this via $PORT)
EXPOSE 8000 3000

# 7. Entrypoint
COPY docker-entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]
# ════════════════════════════════════════════════════
#  LinguaSQL — Dockerfile
#  Optimised for Railway, Fly.io, Render, any Docker host
# ════════════════════════════════════════════════════

FROM python:3.11-slim

# Install system dependencies needed for pymssql, psycopg2, and reportlab
RUN apt-get update && apt-get install -y --no-install-recommends \
    gcc \
    g++ \
    freetds-dev \
    freetds-bin \
    libpq-dev \
    libfreetype6-dev \
    libffi-dev \
    libssl-dev \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Copy requirements first for Docker layer caching
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application files
COPY . .

# Create databases directory (Railway uses ephemeral storage by default;
# mount a Railway Volume to /app/databases for persistence across deploys)
RUN mkdir -p databases databases/uploads

# Move frontend into place if index.html is in project root
RUN mkdir -p static && \
    if [ -f index.html ] && [ ! -f static/index.html ]; then \
        cp index.html static/index.html; \
    fi

# Railway injects PORT at runtime; default to 8000 for local Docker runs
ENV PORT=8000

# Expose port
EXPOSE 8000

# Health check (Railway also hits /health via railway.json)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://localhost:${PORT}/health')"

# Start the app
CMD ["python", "server.py"]

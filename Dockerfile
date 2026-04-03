# ════════════════════════════════════════════════════
#  LinguaSQL — Dockerfile
#  Optimised for Railway, Fly.io, Render
# ════════════════════════════════════════════════════

FROM python:3.11-slim

# ── System dependencies ───────────────────────────────────────────────────────
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

WORKDIR /app

# ── Python dependencies ───────────────────────────────────────────────────────
COPY requirements.txt .

# Install all packages except pymssql first (guaranteed to succeed)
RUN pip install --no-cache-dir $(grep -v pymssql requirements.txt | grep -v '^#' | grep -v '^$' | tr '\n' ' ')

# Install pymssql separately — if it fails the rest of the app still works;
# only SQL Server connections will be unavailable.
RUN pip install --no-cache-dir pymssql==2.3.1 || \
    echo "WARNING: pymssql install failed — MS SQL Server connections unavailable"

# ── Application files ─────────────────────────────────────────────────────────
COPY . .

# Put index.html where the server expects it (static/index.html)
RUN mkdir -p static && \
    if [ -f index.html ] && [ ! -f static/index.html ]; then \
        cp index.html static/index.html; \
    fi

# Ensure database directories exist
RUN mkdir -p databases databases/uploads

# ── Environment ───────────────────────────────────────────────────────────────
# Do NOT hardcode PORT here — Railway injects it at runtime.
# The app reads: int(os.environ.get("PORT", 8000))
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# EXPOSE is documentation only on Railway; the actual port comes from $PORT
EXPOSE 8000

# ── Health check ─────────────────────────────────────────────────────────────
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD python -c "import urllib.request, os; urllib.request.urlopen('http://localhost:' + os.environ.get('PORT','8000') + '/health')"

CMD ["python", "server.py"]
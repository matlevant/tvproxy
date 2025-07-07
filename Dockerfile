# Dockerfile per TVProxy - Server Proxy con Gunicorn (Multi-stage build)

# Stage 1: Build stage
FROM python:3.12-slim as builder

# Installa dipendenze di sistema per build
RUN apt-get update && apt-get install -y \
    gcc \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

# Copia requirements e installa dipendenze
COPY requirements.txt .
RUN pip install --upgrade pip
RUN pip install --no-cache-dir -r requirements.txt

# Stage 2: Runtime stage
FROM python:3.12-slim

# Installa solo le dipendenze runtime necessarie
RUN apt-get update && apt-get install -y \
    git \
    ca-certificates \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Copia le dipendenze Python dalla build stage
COPY --from=builder /usr/local/lib/python3.12/site-packages /usr/local/lib/python3.12/site-packages
COPY --from=builder /usr/local/bin /usr/local/bin

# Imposta la directory di lavoro
WORKDIR /app

# Copia il codice dell'applicazione
COPY . .

# 7. Espone la porta 7860 per Gunicorn
EXPOSE 7860

# 8. Comando per avviare Gunicorn ottimizzato per proxy server
#    - 4 worker per gestire più clienti
#    - Worker class sync (più stabile per proxy HTTP)
#    - Timeout adeguati per streaming
#    - Logging su stdout/stderr
CMD ["gunicorn", "app:app", \
     "-w", "4", \
     "--worker-class", "sync", \
     "-b", "0.0.0.0:7860", \
     "--timeout", "120", \
     "--keep-alive", "5", \
     "--max-requests", "1000", \
     "--max-requests-jitter", "100", \
     "--access-logfile", "-", \
     "--error-logfile", "-", \
     "--log-level", "info"]

# Etapa 1: Builder - compila dependències (wheels)
FROM python:3.11-slim AS builder

# 1) Un sol layer d'APT + --no-install-recommends + neteja
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    gcc \
    g++ \
    libpq-dev \
  && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# 2) Copiam requirements abans per aprofitar cache
COPY requirements.txt /app/

# 3) Generam wheels: evita copiar /usr/local sencer al runtime
RUN pip install --upgrade pip \
 && pip wheel --no-cache-dir -r requirements.txt -w /wheels


# Etapa 2: Runtime - només el necessari per executar
FROM python:3.11-slim

# 4) Instal·lam només runtime deps:
#    - libpq5: llibreria runtime per connectar a Postgres (psycopg2)
#    - postgresql-client: aporta pg_isready (per l'entrypoint)
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq5 \
    postgresql-client \
  && rm -rf /var/lib/apt/lists/*

# 5) Usuari no-root
RUN useradd -m -r appuser

WORKDIR /app

# 6) Instal·lam les deps des dels wheels (determinístic i net)
COPY --from=builder /wheels /wheels
RUN pip install --no-cache-dir /wheels/* \
 && rm -rf /wheels

# 7) Copiam el codi (propietari correcte)
COPY --chown=appuser:appuser . .

# 8) Flags de python (igual que tens, bé)
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

USER appuser
EXPOSE 8000

# 9) CMD de producció; en dev ho sobreescrius al compose amb runserver
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "wsgi:application"]
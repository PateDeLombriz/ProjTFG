# # Etapa 1: Builder - instala las dependencias (incluyendo gunicorn)
FROM python:3.11-slim AS builder

RUN apt-get update
RUN apt-get install -y build-essential
RUN apt-get install -y gcc
RUN apt-get install -y g++
RUN apt-get install -y libpq-dev
RUN rm -rf /var/lib/apt/lists/*

WORKDIR /app

COPY requirements.txt /app/
RUN pip install --upgrade pip 
RUN pip install --no-cache-dir -r requirements.txt

# Etapa 2: Runtime - prepara la imagen final con el código y dependencias necesarias

FROM python:3.11-slim

RUN useradd -m -r appuser

WORKDIR /app
#Este copy es para copiar los archivos de la app al contenedor
COPY --from=builder /usr/local/lib/python3.11/site-packages/ /usr/local/lib/python3.11/site-packages/ 
COPY --from=builder /usr/local/bin/ /usr/local/bin/
COPY --chown=appuser:appuser . .

ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1 

USER appuser

EXPOSE 8000

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "3", "djangoFl.wsgi:application"]

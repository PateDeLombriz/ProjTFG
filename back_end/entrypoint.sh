#!/bin/sh
set -e

echo "Starting entrypoint..."

# Defaults (pots sobreescriure amb .env)
: "${DJANGO_ENV:=dev}"                 # dev | prod
: "${DJANGO_AUTOMIGRATE:=false}"       # true per fer makemigrations automàtic
: "${DJANGO_SEED:=auto}"               # auto | always | never
: "${DJANGO_RESET_DB:=False}"          # true per esborrar dades (dev només)

# Espera Postgres si l'engine és postgres (o si hi ha host)
if [ "${DATABASE_ENGINE}" = "django.db.backends.postgresql" ] || [ -n "${DATABASE_HOST}" ]; then
  echo "Waiting for PostgreSQL at ${DATABASE_HOST}:${DATABASE_PORT}..."
  until pg_isready -h "${DATABASE_HOST}" -p "${DATABASE_PORT}" -U "${DATABASE_USERNAME}" -d "${DATABASE_NAME}" >/dev/null 2>&1; do
    sleep 0.5
  done
  echo "PostgreSQL is ready."
fi

# Reset DB (només dev)
if [ "$DJANGO_RESET_DB" = "true" ]; then
  if [ "$DJANGO_ENV" != "dev" ]; then
    echo "ERROR: DJANGO_RESET_DB=true is only allowed in dev."
    exit 1
  fi
  echo "Resetting DB (flush)..."
  python manage.py flush --no-input
fi

# Automigrations (opcional en dev)
if [ "$DJANGO_AUTOMIGRATE" = "true" ]; then
  echo "Running makemigrations..."
  python manage.py makemigrations
fi

echo "Running migrate..."
python manage.py migrate --noinput

# Seed: recomanat via management command "seed"
# - auto: només si BD buida (necessita que implementis manage.py seed --if-empty)
# - always: sempre
# - never: mai
if [ "$DJANGO_SEED" = "always" ]; then
  echo "Seeding (always)..."
  python manage.py seed || true
elif [ "$DJANGO_SEED" = "auto" ]; then
  echo "Seeding (auto if empty)..."
  python manage.py seed --if-empty || true
else
  echo "Seeding disabled."
fi

echo "Entrypoint done. Executing: $*"
exec "$@"
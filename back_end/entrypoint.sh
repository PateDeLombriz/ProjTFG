#!/bin/sh

# Aqui es definei que passa cada vegada que arranca. S'executa cada vegada que arranques el contenior
if [ "$DATABASE" = "obraAgil" ]
then
    echo "Waiting for postgres..."

    while ! nc -z $SQL_HOST $SQL_PORT; do
      sleep 0.1
    done

    echo "PostgreSQL started"
fi

#python manage.py flush --no-input #flush només buida dades, no recrea l’esquema
python manage.py makemigrations #Crea el pla de canvis (fitxers de migració) a partir de models.py
python manage.py migrate   # Aplica el pla a la base de dades.

exec "$@"
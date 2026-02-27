#!/bin/sh


echo "Waiting for postgres..."
while ! python -c "import socket; s = socket.socket(socket.AF_INET, socket.SOCK_STREAM); s.connect(('$POSTGRES_HOST', int('$POSTGRES_PORT'))); s.close()" 2>/dev/null; do
  sleep 0.1
done
echo "PostgreSQL started"


uv run sh -c "python manage.py makemigrations --noinput"
uv run sh -c "python manage.py migrate --noinput"
uv run sh -c "python manage.py init_admin"
uv run sh -c "python manage.py collectstatic --noinput"

exec "$@"
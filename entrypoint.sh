#!/bin/sh

echo "Запуск Django API бэкенда на 127.0.0.1:8000..."
python /app/backend/manage.py runserver 127.0.0.1:8000 &

echo "Запуск Nginx..."
nginx -g "daemon off;"

#!/bin/bash
set -e

# Wait for MySQL to be ready
echo "Waiting for MySQL to be ready..."
while ! nc -z mysql 3306; do
  echo "Waiting for MySQL..."
  sleep 1
done

echo "MySQL is ready!"

# Give it a few more seconds to be fully initialized
sleep 3

# Run the app
exec uvicorn app.main:app --host 0.0.0.0 --port 8000 --reload

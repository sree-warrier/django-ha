#!/bin/sh

# Check for DB health

echo "Waiting for mysql to come up"
sleep 30

migration_check_flag=$(python /code/manage.py showmigrations | grep '\[ \]' -c)

if [ $migration_check_flag != 0 ]; then
  # Apply database makemigrations
  echo "Make migrations"
  python /code/manage.py makemigrations

  # Apply database migrations
  echo "Apply database migrations"
  python /code/manage.py migrate
fi

# Start server
echo "Starting server"
python /code/manage.py runserver 0.0.0.0:8000

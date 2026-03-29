#!/bin/sh
set -e
# Run migrations once in the container main process before Gunicorn forks workers.
# Parallel Alembic from multiple workers races on MySQL DDL and kills the master.
cd /app
alembic upgrade head
exec "$@"

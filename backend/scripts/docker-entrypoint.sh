#!/bin/sh
set -e
echo "Running alembic upgrade head..."
alembic upgrade head
exec "$@"

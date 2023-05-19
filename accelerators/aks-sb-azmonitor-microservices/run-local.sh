#!/bin/bash
set -e

script_dir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [[ ! -f "$script_dir/.env" ]]; then
  echo "Please create a .env file (using .env.sample as a starter)" 1>&2
  exit 1
fi

source "$script_dir/.env"

if [[ -z "$USERNAME" ]]; then
  echo 'USERNAME not set - ensure you have specifed a value for it in your .env file' 1>&2
  exit 6
fi

echo "Starting services locally (Ctrl+C to stop)"
cd "$script_dir/src"
docker compose up

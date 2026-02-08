#!/bin/bash
#
# setup-data-dir.sh
# Initializes the SUPABASE_DATA_DIR on /mnt/data/supabase
# Run this ONCE after cloning the repo, before 'docker compose up'
#

set -e

# Load .env if it exists
if [ -f .env ]; then
  export $(grep -v '^#' .env | grep SUPABASE_DATA_DIR | xargs)
fi

DATA_DIR="${SUPABASE_DATA_DIR:-/mnt/data/supabase}"

echo "============================================="
echo "  Supabase Data Directory Setup"
echo "  Target: ${DATA_DIR}"
echo "============================================="
echo ""

# Check if /mnt/data is mounted
if ! mountpoint -q /mnt/data 2>/dev/null; then
  echo "WARNING: /mnt/data does not appear to be a mount point."
  echo "Make sure /dev/sda3 is mounted to /mnt/data before continuing."
  read -p "Continue anyway? (y/N): " confirm
  if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
    echo "Aborted."
    exit 1
  fi
fi

# Create the target volumes directory
echo "Creating directory structure at ${DATA_DIR}/volumes ..."
mkdir -p "${DATA_DIR}/volumes"

# Copy default volumes from repo (only files that don't already exist)
if [ -d "./volumes" ]; then
  echo "Copying default config files from ./volumes ..."

  # Use rsync if available (skip existing files), otherwise use cp
  if command -v rsync &>/dev/null; then
    rsync -a --ignore-existing ./volumes/ "${DATA_DIR}/volumes/"
  else
    cp -rn ./volumes/* "${DATA_DIR}/volumes/" 2>/dev/null || cp -r ./volumes/* "${DATA_DIR}/volumes/"
  fi
else
  echo "ERROR: ./volumes directory not found in current directory."
  echo "Make sure you run this script from the docker/ directory."
  exit 1
fi

# Create additional directories that Docker would create on first run
mkdir -p "${DATA_DIR}/volumes/db/data"
mkdir -p "${DATA_DIR}/volumes/db/config"
mkdir -p "${DATA_DIR}/volumes/storage"
mkdir -p "${DATA_DIR}/volumes/snippets"
mkdir -p "${DATA_DIR}/volumes/backups"

echo ""
echo "============================================="
echo "  DONE! Directory structure created:"
echo "============================================="
echo ""
echo "  ${DATA_DIR}/volumes/"
echo "  ├── api/kong.yml"
echo "  ├── db/"
echo "  │   ├── data/          <- PostgreSQL data (your tables)"
echo "  │   ├── config/        <- pgsodium encryption keys"
echo "  │   ├── realtime.sql"
echo "  │   ├── webhooks.sql"
echo "  │   ├── roles.sql"
echo "  │   ├── jwt.sql"
echo "  │   ├── _supabase.sql"
echo "  │   ├── logs.sql"
echo "  │   └── pooler.sql"
echo "  ├── functions/         <- Edge functions"
echo "  ├── logs/vector.yml"
echo "  ├── pooler/pooler.exs"
echo "  ├── snippets/          <- SQL snippets"
echo "  ├── storage/           <- Uploaded files"
echo "  └── backups/           <- For your pg_dump backups"
echo ""
echo "Now run:  docker compose up -d"
echo ""

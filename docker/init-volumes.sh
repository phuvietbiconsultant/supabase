#!/bin/sh
set -e

echo "Initializing Supabase data directory..."

# Copy default config files (only if they don't exist)
# We use find and copy files one by one to avoid overwriting existing files
cd /docker-volumes-defaults
find . -type f | while IFS= read -r file; do
  # Remove leading './' and validate path doesn't escape the target directory
  clean_file="${file#./}"
  case "$clean_file" in
    ..*|/*) 
      echo "Skipping suspicious file path: $file"
      continue
      ;;
  esac
  
  target="/supabase-data/$clean_file"
  if [ ! -f "$target" ]; then
    mkdir -p "$(dirname "$target")"
    cp "$file" "$target"
  fi
done

# Create required empty directories
mkdir -p /supabase-data/db/data
mkdir -p /supabase-data/db/config
mkdir -p /supabase-data/storage
mkdir -p /supabase-data/snippets

echo "Initialization complete."

#!/bin/sh
echo "Running tests with busted..."

if ! busted; then
  echo "Tests failed. Push aborted."
  exit 1
fi

echo "Running luacheck..."

if ! luacheck lua plugin scripts; then
  echo "luacheck failed. Push aborted."
  exit 1
fi

echo "Updating default config in docs..."
scripts/docs_update_default_config/main.sh

exit 0

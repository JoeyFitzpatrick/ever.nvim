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

exit 0

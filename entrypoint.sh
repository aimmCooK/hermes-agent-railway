#!/usr/bin/env bash
set -e

AUTO_UPDATE="${AUTO_UPDATE:-true}"
HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
mkdir -p "$HERMES_HOME"
export HERMES_ALLOW_ROOT_GATEWAY=1

# Persist the Railway session token into Hermes' env file.
if [ -n "${HERMES_DASHBOARD_SESSION_TOKEN:-}" ]; then
  touch "$HERMES_HOME/.env"

  if grep -q '^HERMES_DASHBOARD_SESSION_TOKEN=' "$HERMES_HOME/.env"; then
    sed -i "s|^HERMES_DASHBOARD_SESSION_TOKEN=.*|HERMES_DASHBOARD_SESSION_TOKEN=${HERMES_DASHBOARD_SESSION_TOKEN}|" "$HERMES_HOME/.env"
  else
    echo "HERMES_DASHBOARD_SESSION_TOKEN=${HERMES_DASHBOARD_SESSION_TOKEN}" >> "$HERMES_HOME/.env"
  fi
fi

if [ "$AUTO_UPDATE" = "true" ]; then
  echo "Checking for Hermes updates..."
  cd /opt/hermes-agent

  if git pull --recurse-submodules 2>&1 | grep -v 'Already up to date'; then
    echo "Updating dependencies..."
    VIRTUAL_ENV=/opt/hermes-agent/venv uv pip install -e ".[all]" --quiet
    echo "Update complete."
  else
    echo "Already up to date."
  fi
fi

PORT="${PORT:-9119}"

# Start the messaging gateway in the background (runs as root on this image)
env HERMES_ALLOW_ROOT_GATEWAY=1 hermes gateway run > "$HERMES_HOME/logs/gateway-boot.log" 2>&1 &

exec hermes dashboard \
  --host 0.0.0.0 \
  --port "$PORT" \
  --no-open \
  --insecure \
  --skip-build

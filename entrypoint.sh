#!/usr/bin/env bash
set -e

AUTO_UPDATE="${AUTO_UPDATE:-true}"

# Write session token to Hermes .env if set
if [ -n "$HERMES_DASHBOARD_SESSION_TOKEN" ]; then
  grep -q 'HERMES_DASHBOARD_SESSION_TOKEN' /root/.hermes/.env 2>/dev/null && \
    sed -i "s|^HERMES_DASHBOARD_SESSION_TOKEN=.*|HERMES_DASHBOARD_SESSION_TOKEN=$HERMES_DASHBOARD_SESSION_TOKEN|" /root/.hermes/.env || \
    echo "HERMES_DASHBOARD_SESSION_TOKEN=$HERMES_DASHBOARD_SESSION_TOKEN" >> /root/.hermes/.env
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

hermes dashboard --host 127.0.0.1 --port 9119 --no-open --insecure --skip-build &

exec python /auth_proxy.py

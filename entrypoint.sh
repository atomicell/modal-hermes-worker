#!/usr/bin/env bash
set -e

# Default Hermes configuration directory
export HERMES_HOME="${HERMES_HOME:-/root/.hermes}"
mkdir -p "${HERMES_HOME}"
mkdir -p "${HERMES_HOME}/hindsight"

# Initialize config files if not already present
if [ ! -f "${HERMES_HOME}/config.yaml" ] && [ -f /etc/hermes/config.yaml ]; then
    cp /etc/hermes/config.yaml "${HERMES_HOME}/config.yaml"
fi

if [ ! -f "${HERMES_HOME}/SOUL.md" ] && [ -f /etc/hermes/SOUL.md ]; then
    cp /etc/hermes/SOUL.md "${HERMES_HOME}/SOUL.md"
fi

if [ ! -f "${HERMES_HOME}/hindsight/config.json" ] && [ -f /etc/hermes/hindsight/config.json ]; then
    cp /etc/hermes/hindsight/config.json "${HERMES_HOME}/hindsight/config.json"
fi

# Map legacy environment variables if CHEAPERINFERENCE_API_KEY is not directly supplied
if [ -z "${CHEAPERINFERENCE_API_KEY:-}" ]; then
    if [ -n "${HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY:-}" ]; then
        export CHEAPERINFERENCE_API_KEY="${HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY}"
    elif [ -n "${OPENAI_API_KEY:-}" ]; then
        export CHEAPERINFERENCE_API_KEY="${OPENAI_API_KEY}"
    fi
fi

# Override Hindsight API URL and update API key in config if specified via env
if [ -f "${HERMES_HOME}/hindsight/config.json" ]; then
    python3 -c "
import json, os
p = '${HERMES_HOME}/hindsight/config.json'
try:
    with open(p, 'r') as f:
        cfg = json.load(f)
    if os.environ.get('HINDSIGHT_API_KEY'):
        cfg['apiKey'] = os.environ['HINDSIGHT_API_KEY']
    if os.environ.get('HINDSIGHT_API_URL'):
        cfg['api_url'] = os.environ['HINDSIGHT_API_URL']
    with open(p, 'w') as f:
        json.dump(cfg, f, indent=2)
except Exception as e:
    pass
" 2>/dev/null || true
fi

# Ensure omnigent hermes_native policy hook path is resolved
if [ -f /opt/venv/lib/python3.12/site-packages/omnigent/inner/hermes_policy_hook.py ]; then
    mkdir -p /opt/venv/lib/python3.12/site-packages/omnigent/harnesses/hermes_native/inner
    cp -f /opt/venv/lib/python3.12/site-packages/omnigent/inner/hermes_policy_hook.py /opt/venv/lib/python3.12/site-packages/omnigent/harnesses/hermes_native/inner/hermes_policy_hook.py 2>/dev/null || true
fi

# Execute command or default to hermes
if [ "$#" -eq 0 ]; then
    exec hermes
else
    exec "$@"
fi

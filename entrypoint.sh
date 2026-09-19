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

# Override Hindsight API URL if specified via env
if [ -n "${HINDSIGHT_API_URL:-}" ]; then
    export HINDSIGHT_API_URL
fi

# Ensure omnigent hermes_native policy hook path is resolved
python3 -c "import omnigent, os, pathlib; inner = pathlib.Path(omnigent.__file__).parent / 'inner'; target = pathlib.Path(omnigent.__file__).parent / 'harnesses' / 'hermes_native' / 'inner'; os.makedirs(target.parent, exist_ok=True); (not target.exists() and not os.path.islink(target)) and os.symlink(inner, target)" 2>/dev/null || true

# Execute command or default to hermes
if [ "$#" -eq 0 ]; then
    exec hermes
else
    exec "$@"
fi

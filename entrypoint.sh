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

if [ ! -f "${HERMES_HOME}/hermes_otel.yaml" ] && [ -f /etc/hermes/hermes_otel.yaml ]; then
    cp /etc/hermes/hermes_otel.yaml "${HERMES_HOME}/hermes_otel.yaml"
fi

mkdir -p "${HERMES_HOME}/plugins/hermes_otel"
if [ ! -f "${HERMES_HOME}/plugins/hermes_otel/config.yaml" ] && [ -f /etc/hermes/plugins/hermes_otel/config.yaml ]; then
    cp /etc/hermes/plugins/hermes_otel/config.yaml "${HERMES_HOME}/plugins/hermes_otel/config.yaml"
fi

# Initialize Codex configuration when the base image does not provide one.
export CODEX_HOME="${CODEX_HOME:-/root/.codex}"
mkdir -p "${CODEX_HOME}"
if [ ! -f "${CODEX_HOME}/config.toml" ] && [ -f /etc/codex/config.toml ]; then
    cp /etc/codex/config.toml "${CODEX_HOME}/config.toml"
fi

# Map legacy environment variables if CHEAPERINFERENCE_API_KEY is not directly supplied
if [ -z "${CHEAPERINFERENCE_API_KEY:-}" ]; then
    if [ -n "${HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY:-}" ]; then
        export CHEAPERINFERENCE_API_KEY="${HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY}"
    elif [ -n "${OPENAI_API_KEY:-}" ]; then
        export CHEAPERINFERENCE_API_KEY="${OPENAI_API_KEY}"
    fi
fi

# Default Telemetry and MLflow Tracing environment variables
export OMNIGENT_TELEMETRY_ENABLED="${OMNIGENT_TELEMETRY_ENABLED:-true}"
export OTEL_EXPORTER_OTLP_ENDPOINT="${OTEL_EXPORTER_OTLP_ENDPOINT:-https://159.195.251.138.sslip.io:5000}"
export OTEL_EXPORTER_OTLP_PROTOCOL="${OTEL_EXPORTER_OTLP_PROTOCOL:-http/protobuf}"
export OTEL_EXPORTER_OTLP_TRACES_HEADERS="${OTEL_EXPORTER_OTLP_TRACES_HEADERS:-Authorization=Basic __REDACTED_MLFLOW_CREDENTIAL__,x-mlflow-experiment-id=1}"
export OMNIGENT_OTEL_HTTP_CLIENT_INSTRUMENTATION="${OMNIGENT_OTEL_HTTP_CLIENT_INSTRUMENTATION:-false}"
export OMNIGENT_OTEL_CAPTURE_CONTENT="${OMNIGENT_OTEL_CAPTURE_CONTENT:-true}"
export MLFLOW_TRACKING_USERNAME="${MLFLOW_TRACKING_USERNAME:-admin}"
export MLFLOW_TRACKING_PASSWORD="${MLFLOW_TRACKING_PASSWORD:-__REDACTED_MLFLOW_CREDENTIAL__}"

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

# Ensure OpenAI chat completions compatibility with tools when reasoning_effort is enabled
python3 -c "
p = '/opt/hermes-agent/agent/transports/chat_completions.py'
import os
if os.path.exists(p):
    with open(p, 'r') as f:
        content = f.read()
    target = 'api_kwargs.update(top_level_from_profile)'
    replacement = 'api_kwargs.update(top_level_from_profile)\n        if tools and api_kwargs.get(\"reasoning_effort\") not in (None, \"none\") and not params.get(\"is_kimi\"):\n            api_kwargs[\"reasoning_effort\"] = \"none\"'
    if target in content and replacement not in content:
        content = content.replace(target, replacement)
        with open(p, 'w') as f:
            f.write(content)
" 2>/dev/null || true

# Execute command or default to hermes. Explicitly enforce the Codex proxy
# endpoint because Codex may be invoked with a custom command or config home.
if [ "${1:-}" = "codex" ] || [ "${1:-}" = "/usr/local/bin/codex" ]; then
    shift
    exec codex --config 'openai_base_url="https://159.195.251.138.sslip.io:5000/gateway/proxy/codex/v1"' "$@"
fi

if [ "$#" -eq 0 ]; then
    exec hermes
else
    exec "$@"
fi

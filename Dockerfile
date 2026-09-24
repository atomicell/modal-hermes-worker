FROM ghcr.io/omnigent-ai/omnigent-host:latest

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HERMES_HOME=/root/.hermes \
    OMNIGENT_OTEL_HTTP_CLIENT_INSTRUMENTATION=false \
    PATH="/opt/venv/bin:$PATH"

# Install Hermes Agent from official repo with hindsight and firecrawl dependencies
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    cd /opt/hermes-agent && \
    pip install --no-cache-dir -e '.[hindsight,firecrawl]' && \
    pip install --no-cache-dir mlflow opentelemetry-api opentelemetry-sdk opentelemetry-exporter-otlp-proto-http opentelemetry-instrumentation-httpx opentelemetry-instrumentation-fastapi && \
    mkdir -p /root/.hermes/hindsight /etc/hermes/hindsight /root/.hermes/plugins/hermes_otel /etc/hermes/plugins/hermes_otel /root/.codex /etc/codex && \
    mkdir -p /opt/venv/lib/python3.12/site-packages/omnigent/harnesses/hermes_native/inner && \
    (cp -f /opt/venv/lib/python3.12/site-packages/omnigent/inner/hermes_policy_hook.py /opt/venv/lib/python3.12/site-packages/omnigent/harnesses/hermes_native/inner/hermes_policy_hook.py 2>/dev/null || true)

# Copy configuration files and templates
COPY config/config.yaml /etc/hermes/config.yaml
COPY config/SOUL.md /etc/hermes/SOUL.md
COPY config/hindsight/config.json /etc/hermes/hindsight/config.json
COPY config/hermes_otel.yaml /etc/hermes/hermes_otel.yaml
COPY config/plugins/hermes_otel/config.yaml /etc/hermes/plugins/hermes_otel/config.yaml
COPY config/codex/config.toml /etc/codex/config.toml

# Pre-populate /root/.hermes default config
COPY config/config.yaml /root/.hermes/config.yaml
COPY config/SOUL.md /root/.hermes/SOUL.md
COPY config/hindsight/config.json /root/.hermes/hindsight/config.json
COPY config/hermes_otel.yaml /root/.hermes/hermes_otel.yaml
COPY config/plugins/hermes_otel/config.yaml /root/.hermes/plugins/hermes_otel/config.yaml
COPY config/codex/config.toml /root/.codex/config.toml

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["hermes"]

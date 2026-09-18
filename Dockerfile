FROM ghcr.io/omnigent-ai/omnigent-host:latest

ENV DEBIAN_FRONTEND=noninteractive \
    PYTHONUNBUFFERED=1 \
    HERMES_HOME=/root/.hermes \
    PATH="/opt/venv/bin:$PATH" \
    OMNIGENT_RUNNER_ENV_PASSTHROUGH="HERMES_CUSTOM_API_CHEAPERINFERENCE_COM_API_KEY,CHEAPERINFERENCE_API_KEY,HINDSIGHT_API_KEY,HINDSIGHT_API_URL,HERMES_HOME"

# Install Hermes Agent from official repo with hindsight and firecrawl dependencies
RUN git clone --depth 1 https://github.com/NousResearch/hermes-agent.git /opt/hermes-agent && \
    cd /opt/hermes-agent && \
    pip install --no-cache-dir -e '.[hindsight,firecrawl]' && \
    mkdir -p /root/.hermes/hindsight /etc/hermes/hindsight

# Copy configuration files and templates
COPY config/config.yaml /etc/hermes/config.yaml
COPY config/SOUL.md /etc/hermes/SOUL.md
COPY config/hindsight/config.json /etc/hermes/hindsight/config.json

# Pre-populate /root/.hermes default config
COPY config/config.yaml /root/.hermes/config.yaml
COPY config/SOUL.md /root/.hermes/SOUL.md
COPY config/hindsight/config.json /root/.hermes/hindsight/config.json

# Copy entrypoint script
COPY entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

WORKDIR /root

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["hermes"]

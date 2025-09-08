FROM alpine:3.19

LABEL maintainer="EasyPanel User"
LABEL description="cagent AI Agent Runtime"

ENV CAGENT_HOME=/app
ENV PATH="$PATH:/usr/local/bin"

RUN apk add --no-cache \
    curl \
    wget \
    git \
    ca-certificates \
    bash \
    && rm -rf /var/cache/apk/*

WORKDIR /app

RUN mkdir -p /app/agents /app/config /app/data /app/logs

RUN echo "Descargando cagent..." && \
    wget https://github.com/docker/cagent/releases/latest/download/cagent-linux-amd64 -O /usr/local/bin/cagent && \
    chmod +x /usr/local/bin/cagent && \
    cagent version

RUN cat > /app/agents/basic_agent.yaml << 'EOF'
agents:
  root:
    model: openai/gpt-3.5-turbo
    description: A helpful AI assistant
    instruction: |
      You are a knowledgeable assistant that helps users with various tasks. Be helpful, accurate, and concise in your responses.

models:
  openai/gpt-3.5-turbo:
    provider: openai
    model: gpt-3.5-turbo
    max_tokens: 2000
EOF

RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
echo "🚀 Iniciando cagent..."
echo "✅ cagent versión: $(cagent version)"
echo "▶️ Ejecutando cagent..."
cagent run /app/agents/basic_agent.yaml
EOF

RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/start.sh

EXPOSE 8080

RUN adduser -D -s /bin/bash cagent && \
    chown -R cagent:cagent /app
USER cagent

ENTRYPOINT ["/app/start.sh"]
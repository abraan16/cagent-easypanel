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
    model: openai/gpt-4
    description: A helpful AI assistant
    instruction: |
      You are a knowledgeable assistant that helps users with various tasks. Be helpful, accurate, and concise in your responses.

models:
  openai/gpt-4:
    provider: openai
    model: gpt-4
    max_tokens: 2000
EOF

RUN cat > /app/start.sh << 'EOF'
#!/bin/bash

echo "🚀 Iniciando cagent..."

echo "--- Variables de entorno ---"
echo "OPENAI_API_KEY: ${OPENAI_API_KEY:+presente}"
echo "ANTHROPIC_API_KEY: ${ANTHROPIC_API_KEY:+presente}"
echo "GOOGLE_API_KEY: ${GOOGLE_API_KEY:+presente}"
echo "--------------------------"

if [ ! -x "/usr/local/bin/cagent" ]; then
    echo "❌ Error: cagent no se encuentra o no es ejecutable."
    exit 1
fi

echo "✅ cagent versión: $(cagent version)"

if [ -z "$OPENAI_API_KEY" ]; then
    echo "⚠️  Advertencia: La OPENAI_API_KEY es necesaria para el agente por defecto, pero no está configurada."
fi

if [ ! -f "/app/agents/basic_agent.yaml" ]; then
    echo "❌ Error: /app/agents/basic_agent.yaml no encontrado."
    exit 1
fi

echo "📁 Agentes disponibles:"
ls -la /app/agents/

echo "▶️ Ejecutando cagent..."
cagent run /app/agents/basic_agent.yaml
EOF

# Corrige los finales de línea de Windows (CRLF) a formato Unix (LF) Y da permisos de ejecución
RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/start.sh

EXPOSE 8080

VOLUME ["/app/agents", "/app/config", "/app/data"]

RUN adduser -D -s /bin/bash cagent && \
    chown -R cagent:cagent /app
USER cagent

ENTRYPOINT ["/app/start.sh"]
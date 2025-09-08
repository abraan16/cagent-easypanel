FROM alpine:3.19

LABEL maintainer="EasyPanel User"
LABEL description="cagent AI Agent Runtime - Diagnostic Test"

ENV CAGENT_HOME=/app
ENV PATH="$PATH:/usr/local/bin"

RUN apk add --no-cache curl wget git ca-certificates bash && rm -rf /var/cache/apk/*

WORKDIR /app

RUN mkdir -p /app/agents /app/config /app/data /app/logs

RUN echo "Descargando cagent..." && \
    wget https://github.com/docker/cagent/releases/latest/download/cagent-linux-amd64 -O /usr/local/bin/cagent && \
    chmod +x /usr/local/bin/cagent && \
    cagent version

RUN cat > /app/start.sh << 'EOF'
#!/bin/bash
echo "🚀 Realizando prueba de diagnóstico de OpenAI..."
echo "🔑 Verificando API Key de OpenAI... (Los primeros 8 caracteres son): [${OPENAI_API_KEY:0:8}]"

echo "📡 Intentando contactar la API de OpenAI con curl..."

# Este comando intenta listar los modelos de OpenAI
curl https://api.openai.com/v1/models \
  -H "Authorization: Bearer $OPENAI_API_KEY"

echo ""
echo "🏁 Prueba finalizada. Revisa el resultado de curl arriba."
# Mantenemos el contenedor vivo por 5 minutos para poder ver los logs
sleep 300
EOF

RUN sed -i 's/\r$//' /app/start.sh && chmod +x /app/start.sh

EXPOSE 8080

RUN adduser -D -s /bin/bash cagent && \
    chown -R cagent:cagent /app
USER cagent

ENTRYPOINT ["/app/start.sh"]
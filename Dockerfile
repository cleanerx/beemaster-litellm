# LiteLLM Proxy for Beemaster
FROM ghcr.io/berriai/litellm:main-latest

# Copy LiteLLM config
COPY config.yaml /app/config.yaml

# Expose port
EXPOSE 4000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD curl -f http://localhost:4000/health || exit 1

# Start LiteLLM
CMD ["--config", "/app/config.yaml", "--port", "4000"]
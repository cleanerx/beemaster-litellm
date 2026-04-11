# LiteLLM Proxy for Beemaster - Using official image
FROM ghcr.io/berriai/litellm:main-latest

# LiteLLM has its own config system
ENV LITELLM_MASTER_KEY=${LITELLM_MASTER_KEY}
ENV DEEPINFRA_API_KEY=${DEEPINFRA_API_KEY}
ENV DATABASE_URL=${DATABASE_URL}

# Copy config
COPY config.yaml /app/config.yaml

WORKDIR /app

EXPOSE 4000

# LiteLLM entrypoint - just use config file
CMD ["--config", "/app/config.yaml", "--port", "4000"]
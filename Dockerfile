# LiteLLM Proxy for Beemaster
FROM ghcr.io/berriai/litellm:main-latest

# Copy LiteLLM config
COPY config.yaml /app/config.yaml

# Expose port
EXPOSE 4000

# Start LiteLLM (health check is built into the image)
ENTRYPOINT ["litellm"]
CMD ["--config", "/app/config.yaml", "--port", "4000"]
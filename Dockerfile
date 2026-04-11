# LiteLLM - Proper DeepInfra configuration
FROM python:3.11-slim

# Install LiteLLM
RUN pip install litellm

# Create config file
RUN mkdir -p /app
COPY config.yaml /app/config.yaml

WORKDIR /app

EXPOSE 4000

# Start with config file
CMD ["litellm", "--config", "/app/config.yaml", "--port", "4000"]
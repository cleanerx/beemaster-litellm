# LiteLLM Proxy for Beemaster — Raspberry Pi 5 (ARM64)
# Uses python:3.11-slim-bookworm for ARM64 compatibility
# See: https://stephencowchau.medium.com/quick-note-on-running-litellm-on-raspberry-pi-f679c5f780d9
FROM python:3.11-slim-bookworm

# Install LiteLLM with proxy extensions (includes fastapi, prisma, etc.)
RUN pip install --no-cache-dir "litellm[proxy]"

# Install requests for custom auth and callback HTTP calls
RUN pip install --no-cache-dir requests

# Create app directory
WORKDIR /app

# Copy configuration and callbacks
COPY config.yaml /app/config.yaml
COPY callbacks/ /app/callbacks/

EXPOSE 4000

# Run LiteLLM proxy
CMD ["python", "-m", "litellm", "--config", "/app/config.yaml", "--port", "4000"]

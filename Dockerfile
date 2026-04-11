# LiteLLM - Use python -m litellm
FROM python:3.11-slim

# Install LiteLLM
RUN pip install litellm

# Create config file
COPY config.yaml /app/config.yaml

WORKDIR /app

EXPOSE 4000

# Use python -m to call litellm module
CMD ["python", "-m", "litellm", "--config", "/app/config.yaml", "--port", "4000"]
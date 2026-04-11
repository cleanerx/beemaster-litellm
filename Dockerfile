# Simple Test - Just Run LiteLLM
FROM python:3.11-slim

# Install LiteLLM via pip
RUN pip install litellm

# Copy config
COPY config.yaml /app/config.yaml
WORKDIR /app

# Expose port
EXPOSE 4000

# Start
CMD ["litellm", "--config", "/app/config.yaml", "--port", "4000", "--detailed_debug"]
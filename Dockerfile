# LiteLLM Proxy for Beemaster - NPM Installation
FROM node:20-alpine

# Install LiteLLM
RUN npm install -g litellm

# Create app directory
WORKDIR /app

# Copy config
COPY config.yaml /app/config.yaml

# Expose port
EXPOSE 4000

# Start LiteLLM
CMD ["litellm", "--config", "/app/config.yaml", "--port", "4000"]
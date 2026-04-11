# LiteLLM Proxy - Minimal setup
FROM ghcr.io/berriai/litellm:main-latest

EXPOSE 4000

# LiteLLM streams config from environment
CMD ["--model", "deepinfra/nvidia/Nemotron-3-Nano-30B-A3B", "--port", "4000"]
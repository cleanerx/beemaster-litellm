# LiteLLM Proxy - Minimal setup
FROM python:3.11-slim

RUN pip install litellm

EXPOSE 4000

# Use ENTRYPOINT + CMD properly
ENTRYPOINT ["litellm"]
CMD ["--model", "deepinfra/nvidia/Nemotron-3-Nano-30B-A3B", "--port", "4000"]
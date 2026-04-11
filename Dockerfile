# Minimal LiteLLM Dockerfile
FROM python:3.11-slim

RUN pip install litellm

EXPOSE 4000

CMD ["litellm", "--model", "deepinfra/nvidia/Nemotron-3-Nano-30B-A3B", "--port", "4000", "--detailed_debug"]
FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y git bash curl && rm -rf /var/lib/apt/lists/*
RUN groupadd -r agent && useradd -r -g agent -m agent
USER agent
WORKDIR /workspace

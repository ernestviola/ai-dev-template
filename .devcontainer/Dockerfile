FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y git bash curl && rm -rf /var/lib/apt/lists/*
RUN groupadd -r agent && useradd -r -g agent -m agent
USER agent
RUN git config --global include.path /home/agent/.gitconfig-host
RUN git config --global credential.helper '!f() { echo "username=x-access-token"; echo "password=$GITHUB_TOKEN"; }; f'
WORKDIR /workspace
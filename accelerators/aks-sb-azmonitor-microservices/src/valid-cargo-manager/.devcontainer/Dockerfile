ARG VARIANT="6.0"
FROM mcr.microsoft.com/vscode/devcontainers/dotnet:0-${VARIANT}

ARG USERNAME=vscode

RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install telnet -y

FROM fedora:37

LABEL org.opencontainers.image.source="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.authors="https://github.com/mpepping"
LABEL org.opencontainers.image.url="ghcr.io/mpepping/podshell/shell:latest"
LABEL org.opencontainers.image.documentation="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.title="shell"

RUN dnf -y update && \
    dnf -y install \
      curl \
      iproute \
      mosh \
      skopeo \
      tmux \
      vim \
      wget && \
    dnf clean all && \
    useradd -c "Pod User" -m -g users podshell

USER podshell
WORKDIR /home/podshell

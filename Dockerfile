FROM alpine:3

LABEL org.opencontainers.image.source="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.authors="https://github.com/mpepping"
LABEL org.opencontainers.image.url="ghcr.io/mpepping/podshell/shell:latest"
LABEL org.opencontainers.image.documentation="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.title="shell"

RUN apk add --no-cache \
      bash \
      curl \
      iproute2 \
      mosh-client \
      openssl \
      skopeo \
      tmux \
      vim \
      wget && \
    addgroup -g 1000 podshell && \
    adduser -D -u 1000 -G podshell podshell

USER 1000
WORKDIR /home/podshell

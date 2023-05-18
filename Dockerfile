FROM alpine:3

LABEL org.opencontainers.image.source="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.authors="https://github.com/mpepping"
LABEL org.opencontainers.image.url="ghcr.io/mpepping/podshell/shell:latest"
LABEL org.opencontainers.image.documentation="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.title="shell"

ADD include/ /

RUN apk add --no-cache \
      bash \
      bash-completion \
      curl \
      iproute2 \
      jq \
      openssl \
      skopeo \
      tmux \
      vim \
      wget && \
    addgroup -g 1000 podshell && \
    adduser -D -u 1000 -G podshell -s /bin/bash -g "Podshell User" podshell && \
    su - podshell -c "/usr/local/bin/_add_binenv"

USER 1000
WORKDIR /home/podshell

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
CMD [ "bash" ]
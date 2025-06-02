FROM alpine:3.22

LABEL org.opencontainers.image.authors="https://github.com/mpepping"
LABEL org.opencontainers.image.description="PodShell is a container image for development and debug purposes"
LABEL org.opencontainers.image.documentation="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.source="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.title="podshell"
LABEL org.opencontainers.image.url="ghcr.io/mpepping/podshell/shell:latest"

RUN apk add --no-cache \
      atop \
      bash \
      bash-completion \
      bat \
      bind-tools \
      curl \
      htop \
      iftop \
      iperf3 \
      iproute2 \
      jq \
      lsblk \
      lsof \
      man-db \
      man-pages \
      mtr \
      nmap \
      openssh-client \
      openssl \
      procps \
      ripgrep \
      shadow \
      skopeo \
      socat \
      strace \
      sudo \
      tcpdump \
      tmux \
      vim \
      virt-what \
      wget

ADD include/ /

RUN usermod -s /bin/bash root && \
    addgroup -g 1000 podshell && \
    adduser -D -u 1000 -G podshell -s /bin/bash -g "Podshell User" podshell && \
    su - podshell -c "/usr/local/bin/_add_binenv" && \
    su - podshell -c "/usr/local/bin/_add_dbin --install /home/podshell/.local/bin/dbin"

USER 1000
WORKDIR /home/podshell

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
CMD [ "bash" ]

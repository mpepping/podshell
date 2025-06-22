FROM fedora:42

LABEL org.opencontainers.image.authors="https://github.com/mpepping"
LABEL org.opencontainers.image.description="PodShell is a container image for development and debug purposes"
LABEL org.opencontainers.image.documentation="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.source="https://github.com/mpepping/podshell"
LABEL org.opencontainers.image.title="podshell"
LABEL org.opencontainers.image.url="ghcr.io/mpepping/podshell/shell:latest"

RUN dnf install --setopt=install_weak_deps=False --nodocs -y \
        bash \
        bash-completion \
        bat \
        bind-utils \
        curl \
        iftop \
        iperf3 \
        iproute \
        jq \
        lsof \
        nmap \
        openssh-clients \
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
        vim-minimal \
        virt-what \
        wget && \
    dnf clean all && \
    rm -rf /var/cache/dnf /usr/share/doc /usr/share/man /usr/share/locale

ADD include/ /

RUN groupadd -g 1000 podshell && \
    useradd -u 1000 -m -g podshell -s /bin/bash -c "Podshell User" podshell

WORKDIR /home/podshell

RUN sudo -u podshell /usr/local/bin/_add_binenv
RUN sudo -u podshell /usr/local/bin/_add_dbin --install /home/podshell/.local/bin/dbin

USER 1000
WORKDIR /home/podshell

ENTRYPOINT [ "/bin/bash", "-l", "-c" ]
CMD [ "bash" ]

FROM fedora:34
LABEL maintainer="Martijn Pepping <martijn.pepping@automiq.nl>"

EXPOSE 22

RUN dnf -y update && \
    dnf -y install dnf-plugins-core \
       git \
       iproute \
       mosh \
       mutt \
       openssh-server \
       passwd \
       procps-ng \
       tmux \
       vim-enhanced && \
       dnf clean all

RUN dnf config-manager \
      --add-repo https://download.docker.com/linux/fedora/docker-ce.repo && \
    dnf install -y docker-ce-cli && \
    dnf clean all && \
    useradd martijn -u 1026 -c 'Martijn Pepping' -G wheel && \
    ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ''

CMD ["/usr/sbin/sshd", "-D"]

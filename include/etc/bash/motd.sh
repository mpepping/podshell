# shellcheck shell=bash
# Sourced by /etc/bash/bashrc for interactive bash shells, which covers
# `kubectl exec -it <pod> -- bash` (an interactive, non-login shell).

if [ -x /usr/local/bin/podshell-motd ]; then
    /usr/local/bin/podshell-motd
    export PODSHELL_MOTD_SHOWN=1
fi

#!/usr/bin/env bash
# Smoke test for the podshell image. Verifies that the expected tooling is
# present and usable as the unprivileged `podshell` user.
#
# Usage: test/smoke.sh [image]           (default: ghcr.io/mpepping/podshell:latest)
#
# Single quotes around the checks are intentional: those expressions are
# evaluated inside the container, not by this script.
# shellcheck disable=SC2016

set -uo pipefail

IMAGE="${1:-${IMAGE:-ghcr.io/mpepping/podshell:latest}}"
RUNTIME="${CONTAINER_RUNTIME:-docker}"

FAILED=0

run() {
    "${RUNTIME}" run --rm --entrypoint /bin/bash "${IMAGE}" -lc "$1"
}

check() {
    local desc="$1" cmd="$2" out
    if out="$(run "${cmd}" 2>&1)"; then
        printf '  ok    %s\n' "${desc}"
    else
        printf '  FAIL  %s\n%s\n' "${desc}" "${out}"
        FAILED=$((FAILED + 1))
    fi
}

echo "==> Testing image: ${IMAGE}"

echo "--> Runtime identity"
check "runs as uid 1000"          '[ "$(id -u)" = "1000" ]'
check "runs as user podshell"     '[ "$(id -un)" = "podshell" ]'
check "home is /home/podshell"    '[ "$HOME" = "/home/podshell" ]'
check "login shell is bash"       '[ -n "$BASH_VERSION" ]'
check "sudo to root works"        '[ "$(sudo id -u)" = "0" ]'

echo "--> Runtime package managers"
check "binenv on PATH"            'command -v binenv >/dev/null && binenv version'
check "dbin on PATH"              'command -v dbin >/dev/null'

echo "--> Bundled tooling"
TOOLS=(
    ab arping atop bat brctl bridge bash conntrack curl dig drill ethtool file
    fping git host htop iftop iperf3 ip iptables ipset ipvsadm jq less lsblk lsns
    lsof man mtr nc nft ngrep nmap nsenter openssl ping ps rg scp skopeo socat ss
    strace sudo tc tcpdump tcptraceroute tmux tput traceroute tree unshare vim
    virt-what websocat wget
)
# Checked in a single container run, to keep the suite fast.
missing="$(run "for t in ${TOOLS[*]}; do command -v \$t >/dev/null || echo \$t; done")"
if [ -n "${missing}" ]; then
    for tool in ${missing}; do
        printf '  FAIL  %s not found\n' "${tool}"
        FAILED=$((FAILED + 1))
    done
else
    printf '  ok    %s tools present\n' "${#TOOLS[@]}"
fi

echo "--> Behaviour"
check "motd shown on interactive login" 'grep -q hushlogin /etc/motd'
check "non-interactive shell is quiet"  '[ -z "$(bash -lc "true")" ]'

echo
if [ "${FAILED}" -gt 0 ]; then
    echo "==> ${FAILED} check(s) failed"
    exit 1
fi
echo "==> All checks passed"

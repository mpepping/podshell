# shellcheck shell=sh
# Show the banner on interactive login shells only, so non-interactive usage
# (`kubectl exec pod -- some-command`) keeps a clean stdout.

case $- in
*i*)
    if [ -x /usr/local/bin/podshell-motd ]; then
        /usr/local/bin/podshell-motd
        PODSHELL_MOTD_SHOWN=1
        export PODSHELL_MOTD_SHOWN
    fi
    ;;
esac

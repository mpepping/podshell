# shellcheck shell=sh
# Make sure binenv and dbin installed binaries are on PATH, also for shells
# that do not inherit the image PATH (su, sudo -i, ...). Idempotent.

for _dir in "${HOME:-/home/podshell}/.local/bin" "${HOME:-/home/podshell}/.binenv"; do
    case ":${PATH}:" in
    *":${_dir}:"*) ;;
    *) PATH="${_dir}:${PATH}" ;;
    esac
done
unset _dir
export PATH

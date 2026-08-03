# AGENTS.md

Guidance for AI coding agents (and new contributors) working in this repository.

## What this project is

`podshell` is a small Alpine-based container image with debug and development tooling, meant to be
shelled into: as a throwaway pod, an ephemeral `kubectl debug` container, a sidecar, a privileged
daemonset, or plain `docker run`. It runs as the unprivileged user `podshell` (uid/gid 1000) with
passwordless `sudo`, so it works under restrictive admission policies.

Two runtime package managers keep the image small: [`binenv`](https://github.com/devops-works/binenv)
and [`dbin`](https://github.com/xplshn/dbin). Prefer them over adding large or niche packages to the
image.

## Layout

| Path | Purpose |
|---|---|
| `Dockerfile` | Single-stage Alpine build: apk packages, user creation, binenv/dbin bootstrap |
| `include/` | Overlay copied to `/` in the image (profile scripts, motd, sudoers, helper scripts) |
| `include/usr/local/bin/_add_binenv`, `_add_dbin` | Bootstrap scripts run at build time as the `podshell` user |
| `include/etc/profile.d/*.sh` | Sourced by login shells |
| `include/etc/bash/motd.sh` | Sourced by `/etc/bash/bashrc` for interactive shells (`kubectl exec -it -- bash`) |
| `k8s/` | Ready-to-use manifests: pod, sidecar, privileged daemonset and deployment |
| `test/smoke.sh` | Post-build verification of identity, PATH and bundled tooling |
| `.github/workflows/ci.yml` | Smoke test job, then multi-arch build, push and cosign signing |

## Build and test commands

```bash
make build          # local platform build, tags ghcr.io/mpepping/podshell:latest
make build-all      # multi-arch buildx build (amd64 + arm64), no push - mirrors CI
make lint           # hadolint on the Dockerfile
make smoke          # run test/smoke.sh against the built image
make start          # interactive shell in the built image
```

There are no unit tests; `test/smoke.sh` is the test suite. Run it after any change to the
`Dockerfile` or `include/`.

## Conventions

- Keep the apk package list alphabetically sorted.
- Every shipped tool needs a check in `test/smoke.sh` and a row in the README "Included tooling"
  table.
- Shell scripts under `include/` must be POSIX `sh` compatible unless they live in `/etc/bash/`,
  and should carry a `# shellcheck shell=...` directive.
- Non-interactive invocations (`kubectl exec pod -- some-command`) must keep stdout clean: the motd
  is only printed for interactive shells, guarded by `PODSHELL_MOTD_SHOWN`.
- `PATH` is set both via `ENV` in the Dockerfile (for non-login shells) and via
  `include/etc/profile.d/bin-paths.sh` (for `su`/`sudo -i`). Keep both in sync.
- Both `linux/amd64` and `linux/arm64` must build; architecture detection in the bootstrap scripts
  maps `x86_64` to `amd64` and `aarch64` to `arm64`.

## Release flow

Pushing to `main` publishes `:main` and `:sha-*` tags. Pushing a `*.*.*` tag publishes semver tags
plus `latest`. All pushed images are signed keylessly with cosign via GitHub OIDC.

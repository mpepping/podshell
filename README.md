# podshell

*Simple and small container env for development and debug purposes.*

By default, the container starts as a regular user, to play nice with potential Kubernetes admission policies. Therefor, the a set of most [useful packages](./Dockerfile) is already installed, while keeping an eye on the container image size. The package list is not exhaustive, but can be extended by using the `binenv` tool. Run [binenv](https://github.com/devops-works/binenv) to install various packages, by running `binenv update`, `binenv search` and `binenv install <pkg>`.

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mpepping/podshell)

## Usage

Imperative and removed on exit:

```bash
kubectl run -it --rm --restart=Never --image=ghcr.io/mpepping/podshell:latest shell
```

Declarative:

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: shell
  name: shell
spec:
  containers:
  - image: ghcr.io/mpepping/podshell:latest
    imagePullPolicy: Always
    name: shell
    command: ["sleep"]
    args: ["86400"]
EOF
```

As a Deployment:

```bash
kubectl create deployment shell --image=ghcr.io/mpepping/podshell:latest -- sleep infinit
```

Or in docker or podman:

```bash
docker run -ti --rm ghcr.io/mpepping/podshell:latest ||\
podman run -ti --rm ghcr.io/mpepping/podshell:latest
```

## Feedback

Open an [issue or PR](https://github.com/mpepping/podshell/issues).

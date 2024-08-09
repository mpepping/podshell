# podshell

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mpepping/podshell)

*Simple and small container env for development and debug purposes.*

By default, the container starts as a regular user, to play nice with potential Kubernetes admission policies. Therefor, the a set of most [useful packages](./Dockerfile) is already installed, while keeping an eye on the container image size. The package list is not exhaustive, but can be extended by using the `binenv` tool. Run [binenv](https://github.com/devops-works/binenv) to install various packages, by running `binenv update`, `binenv search` and `binenv install <pkg>`.

## Usage

**Imperative** and removed on exit:

```bash
kubectl run -it --rm --restart=Never --image=ghcr.io/mpepping/podshell:latest shell
```

**Declarative**:

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Pod
metadata:
  labels:
    name: podshell
  name: podshell
spec:
  containers:
  - image: ghcr.io/mpepping/podshell:latest
    imagePullPolicy: Always
    name: shell
    command: ["sleep"]
    args: ["86400"]
EOF
```

As an imperative **Deployment**:

```bash
kubectl create deployment shell --image=ghcr.io/mpepping/podshell:latest -- sleep infinit
```

As a **privileged daemonset** to add some host level super powers:

```bash
kubectl apply -f k8s/daemonset.yaml
```

This DaemonSet manifest will:

 1. Ensure a pod with our Docker image is running indefinitely on every node.
 2. Use `hostPID`, `hostIPC`, and `hostNetwork`.
 3. Mount the entire host filesystem to `/host` in the containers.

In order to make use of these workloads, you can exec into a pod of choice by name:

```bash
kubectl -n kube-system get pods -l name=podshell -o name
kubectl -n kube-system exec -it PODNAME bash
```

If you know the specific node name that you're interested in, you can exec into the debug pod on that node with:

```bash
NODE_NAME="talos-dev-worker-1"
POD_NAME=$(kubectl -n kube-system get pods -l name=podshell --field-selector spec.nodeName=${NODE_NAME} -ojsonpath='{.items[0].metadata.name}')
kubectl -n kube-system exec -it ${POD_NAME} bash
```

As a **privileged deployment**, instead of a daemonset example:

```bash
kubectl apply -f k8s/deployment.yaml
```

Or in **docker** or **podman**:

```bash
docker run -ti --rm ghcr.io/mpepping/podshell:latest ||\
podman run -ti --rm ghcr.io/mpepping/podshell:latest
```

## Building

[![Container Image](https://github.com/mpepping/podshell/actions/workflows/ci.yml/badge.svg)](https://github.com/mpepping/podshell/actions/workflows/ci.yml)

Run `make` or see the [`Makefile`](/Makefile).

```shell
❯ make
help                           This help.
build                          Build the image
push                           Push the image
clean                          Remove the image
start                          Start the container
stop                           Stop the container
test                           Test the container build
```

## Feedback

Open an [issue or PR](https://github.com/mpepping/podshell/issues).

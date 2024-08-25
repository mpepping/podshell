# podshell

[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mpepping/podshell)

_A simple and small container environment for development and debug purposes._

Podshell is a small set of userland tools you can shell into. The container starts as a regular user (`podshell`, uid `1000`) to play nice with potential admission policies. A set of [useful packages](./Dockerfile) is already installed to provide a functional shell. The package list is not exhaustive, but can be extended at runtime via either [`binenv`](https://github.com/devops-works/binenv) or [`dbin`](https://github.com/xplshn/dbin):

- Run [`binenv`](https://github.com/devops-works/binenv) to install various packages from their original GitHub release repositories, by running `binenv update`, `binenv search` and `binenv install <pkg>`.
- Run [`dbin`](https://github.com/xplshn/dbin) to install various static binaries from the [Toolpacks](https://github.com/Azathothas/Toolpacks) repository, by running `dbin install`, `dbin search`, `dbin list` and `dbin run`.

In a podshell, you can use `sudo` to switch to root if needed. That should be sufficient to run debugging or development tasks that may need root. Optionally, you can run the container as root, by setting `securityContext.runAsUser: 0` in a container spec.

## Usage

**Imperative** as a Pod in Kubernetes and removed on exit:

```bash
kubectl run -it --rm --restart=Never --image=ghcr.io/mpepping/podshell:latest shell
```

**Declarative** as a Pod in Kubernetes:

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

As an imperative **Deployment** one-liner in Kubernetes:

```bash
kubectl create deployment shell --image=ghcr.io/mpepping/podshell:latest -- sleep infinit
```

Or using **docker** or **podman** as container runtime:

```bash
docker run -ti --rm ghcr.io/mpepping/podshell:latest ||\
podman run -ti --rm ghcr.io/mpepping/podshell:latest
```

## Run as a privileged Kubernetes daemonset or deployment

You can use these [yaml examples](./k8s) to deploy the podshell as a privileged daemonset or deployment in Kubernetes.

As a **privileged daemonset**:

```bash
kubectl apply -f k8s/daemonset.yaml
```

This DaemonSet manifest will:

1.  Ensure a pod with our Docker image is running indefinitely on every node.
2.  Use `hostPID`, `hostIPC`, and `hostNetwork`.
3.  Mount the entire host filesystem to `/host` in the containers.

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

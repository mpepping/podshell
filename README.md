# shell

Simple alpine based container env for dev and debug purposes.

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
kubectl create deployment shell --image=ghcr.io/mpepping/podshell:latest -- sleep 86400
```

Or in docker or podman:

```bash
docker run -ti --rm ghcr.io/mpepping/podshell:latest || podman run -ti --rm ghcr.io/mpepping/podshell:latest
```

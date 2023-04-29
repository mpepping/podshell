# shell

Simple alpine based container env for dev and debug purposes.

## Usage

Imperative and removed on exit:

```bash
kubectl run -it --rm --restart=Never --image=ghcr.io/mpepping/podshell/shell:latest shell
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
  - image: ghcr.io/mpepping/podshell/shell:latest
    imagePullPolicy: Always
    name: shell
    command: ["sleep"]
    args: ["86400"]
EOF
```

As a Deployment:

```bash
kubectl create deployment shell --image=ghcr.io/mpepping/podshell/shell:latest -- sleep 86400
```

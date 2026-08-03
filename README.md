# podshell

[![Container Image](https://github.com/mpepping/podshell/actions/workflows/ci.yml/badge.svg)](https://github.com/mpepping/podshell/actions/workflows/ci.yml)
[![Open in GitHub Codespaces](https://github.com/codespaces/badge.svg)](https://codespaces.new/mpepping/podshell)

_A simple and small container environment for development and debug purposes._

Podshell is a small set of userland tools you can shell into, to debug containers, pods, nodes and
networks. It starts as a regular user (`podshell`, uid `1000`) to play nice with admission policies
like the [restricted Pod Security Standard](https://kubernetes.io/docs/concepts/security/pod-security-standards/),
and `sudo` is available for the tasks that need root.

```bash
# Throwaway pod in Kubernetes
kubectl run -it --rm --restart=Never --image=ghcr.io/mpepping/podshell:latest shell

# Debug a running pod, without restarting it
kubectl debug -it <pod-name> --image=ghcr.io/mpepping/podshell:latest

# Debug a node
kubectl debug node/<node-name> -it --image=ghcr.io/mpepping/podshell:latest

# Share a running container's network namespace
docker run -it --rm --net container:<container-name> ghcr.io/mpepping/podshell:latest
```

## Why podshell

Containers are isolated in their own namespaces: their own network stack, processes and mounts.
Production images are (rightfully) minimal and ship no shell tooling. Podshell lets you _enter_
those namespaces with a full toolbox, without changing or rebuilding the workload you are debugging.

- **Debug a container or pod** without baking tools into its image
- **Debug a node** without installing anything on the host
- **Stay small and unprivileged** by default, and escalate only when you need to
- **Extend at runtime** with [`binenv`](https://github.com/devops-works/binenv) and
  [`dbin`](https://github.com/xplshn/dbin) instead of shipping every tool under the sun

## Usage

### Kubernetes

```bash
# Throwaway pod, removed on exit
kubectl run -it --rm --restart=Never --image=ghcr.io/mpepping/podshell:latest shell

# Long-running pod you can exec into later
kubectl run shell --image=ghcr.io/mpepping/podshell:latest -- sleep 86400
kubectl exec -it shell -- bash

# Ephemeral container in an existing pod (shares its network namespace)
kubectl debug -it <pod-name> --image=ghcr.io/mpepping/podshell:latest

# Ephemeral container that also shares the target container's process namespace
kubectl debug -it <pod-name> --image=ghcr.io/mpepping/podshell:latest --target <container-name>

# Debug a node; the node filesystem is mounted at /host
kubectl debug node/<node-name> -it --image=ghcr.io/mpepping/podshell:latest

# Throwaway pod on the host network namespace
kubectl run shell -it --rm --restart=Never \
  --image=ghcr.io/mpepping/podshell:latest \
  --overrides='{"spec":{"hostNetwork":true,"dnsPolicy":"ClusterFirstWithHostNet"}}'

# Imperative deployment one-liner
kubectl create deployment shell --image=ghcr.io/mpepping/podshell:latest -- sleep infinity
```

Ready-to-use manifests live in [`k8s/`](./k8s):

| Manifest | Description |
|---|---|
| [`k8s/pod.yaml`](./k8s/pod.yaml) | Plain unprivileged pod, passes the `restricted` Pod Security Standard |
| [`k8s/sidecar.yaml`](./k8s/sidecar.yaml) | Podshell as a sidecar sharing an application pod |
| [`k8s/daemonset.yaml`](./k8s/daemonset.yaml) | Privileged daemonset on every node, host filesystem at `/host` |
| [`k8s/deployment.yaml`](./k8s/deployment.yaml) | Privileged deployment, host filesystem at `/host` |

```bash
kubectl apply -f k8s/pod.yaml
kubectl exec -it podshell -- bash
```

### Docker and Podman

```bash
# Interactive shell
docker run -it --rm ghcr.io/mpepping/podshell:latest
podman run -it --rm ghcr.io/mpepping/podshell:latest

# Share another container's network namespace: same interfaces, same localhost
docker run -it --rm --net container:<container-name> ghcr.io/mpepping/podshell:latest

# Use the host network namespace
docker run -it --rm --net host ghcr.io/mpepping/podshell:latest

# Packet capture with the required capabilities
docker run -it --rm --net container:web \
  --cap-add NET_RAW --cap-add NET_ADMIN \
  ghcr.io/mpepping/podshell:latest 'sudo tcpdump -nni any port 80'

# Enter the Docker Desktop / hypervisor VM
docker run -it --rm --privileged --pid=host ghcr.io/mpepping/podshell:latest \
  'sudo nsenter -t 1 -m -u -i -n -- bash'
```

### Docker Compose

Attach podshell to a service's network namespace, for example to capture traffic to a pcap file:

```yaml
services:
  nginx:
    image: nginx:alpine
    ports:
      - 8080:80

  podshell:
    image: ghcr.io/mpepping/podshell:latest
    depends_on: [nginx]
    network_mode: "service:nginx" # share nginx's network namespace
    cap_add: ["NET_RAW", "NET_ADMIN"]
    command: "sudo tcpdump -i any -w /data/nginx.pcap"
    volumes:
      - ./data:/data
```

### Privileged daemonset or deployment

The [daemonset](./k8s/daemonset.yaml) and [deployment](./k8s/deployment.yaml) manifests:

1. Run a podshell pod indefinitely (on every node, in case of the daemonset).
2. Use `hostPID`, `hostIPC` and `hostNetwork`.
3. Mount the entire host filesystem at `/host`.

```bash
kubectl apply -f k8s/daemonset.yaml
kubectl -n kube-system get pods -l name=podshell -o name
kubectl -n kube-system exec -it PODNAME -- bash
```

To land on a specific node:

```bash
NODE_NAME="talos-dev-worker-1"
POD_NAME=$(kubectl -n kube-system get pods -l name=podshell \
  --field-selector spec.nodeName=${NODE_NAME} -ojsonpath='{.items[0].metadata.name}')
kubectl -n kube-system exec -it ${POD_NAME} -- bash
```

From such a pod you can inspect the node itself:

```bash
sudo chroot /host          # a shell as if you were on the node
sudo nsenter -t 1 -m -u -i -n -- bash  # enter the host namespaces (PID 1)
```

## Troubleshooting recipes

### DNS resolution

```bash
# What resolver and search domains does this pod use?
cat /etc/resolv.conf

# Resolve a service, the way an application would
dig +search +short my-service.my-namespace.svc.cluster.local
drill my-service.my-namespace.svc

# Query the cluster DNS directly, bypassing /etc/resolv.conf
dig @10.96.0.10 kubernetes.default.svc.cluster.local

# NXDOMAIN vs timeout tells you server-side vs network-side problems
dig +tries=1 +time=2 example.com

# See what actually goes over the wire
sudo tcpdump -nni any port 53
```

### Service reachability and firewalling

```bash
# TCP port check
nc -zv my-service 80

# Port range across a host
nmap -Pn -p 1-1024 10.0.0.10

# Traceroute over TCP to a port, to find where a connection is dropped
tcptraceroute my-service 443

# Local sockets, listeners and their processes
ss -tulpn

# Conntrack state, NAT translations and firewall rules
sudo conntrack -L
sudo iptables -t nat -L -n -v
sudo nft list ruleset
sudo ipvsadm -Ln            # kube-proxy in IPVS mode
```

### Latency, loss and throughput

```bash
# Combined traceroute and ping
mtr -n my-service

# Ping many hosts in parallel
fping -a -g 10.0.0.1 10.0.0.20

# Throughput between two pods
iperf3 -s                   # on pod A
iperf3 -c pod-a-ip -t 30    # on pod B
iperf3 -c pod-a-ip -u -b 100M  # UDP, jitter and loss

# Bandwidth per host pair on an interface
sudo iftop -i eth0
```

### Packet capture and inspection

```bash
# Capture to a file you can pull out with `kubectl cp`
sudo tcpdump -nni any -w /tmp/capture.pcap

# Live capture, filtered
sudo tcpdump -nni eth0 host 10.0.0.10 and port 443

# Grep live traffic, e.g. HTTP host headers
sudo ngrep -d any -q -W byline "Host:" port 80
```

### HTTP, TLS and gRPC endpoints

```bash
# Request timing breakdown
curl -sv -o /dev/null -w 'dns=%{time_namelookup} conn=%{time_connect} tls=%{time_appconnect} ttfb=%{time_starttransfer} total=%{time_total}\n' https://example.com

# Inspect a serving certificate and its chain
openssl s_client -connect example.com:443 -servername example.com </dev/null | openssl x509 -noout -text

# Check certificate expiry only
echo | openssl s_client -connect example.com:443 2>/dev/null | openssl x509 -noout -dates

# Simple HTTP load test
ab -n 1000 -c 20 http://my-service/

# WebSocket endpoint
websocat wss://echo.websocket.org
```

### Interfaces, routing and MTU

```bash
ip -br addr                 # interfaces and addresses
ip route get 10.0.0.10      # which route would be used
ip -s link                  # per interface errors and drops
ip neigh                    # ARP/NDP table
arping -I eth0 10.0.0.1     # layer 2 reachability
sudo ethtool -S eth0        # NIC statistics
brctl show                  # bridges (docker0, cni0, ...)
tracepath my-service        # path MTU discovery
```

### Processes, files and the node

```bash
htop / atop                 # interactive process and resource views
ps auxf                     # process tree (needs shareProcessNamespace or hostPID)
sudo lsof -p <pid>          # open files and sockets of a process
sudo strace -p <pid> -f     # syscall trace
lsblk                       # block devices (privileged pods)
virt-what                   # which hypervisor are we on
sudo skopeo inspect docker://ghcr.io/mpepping/podshell:latest  # registry/image inspection
```

## Included tooling

| Area | Tools |
|---|---|
| Shell and editing | `bash`, `bash-completion`, `vim`, `tmux`, `less`, `bat`, `ripgrep`, `tree`, `file`, `git`, `man` |
| DNS | `bind-tools` (`dig`, `host`, `nslookup`), `drill` |
| Network analysis | `tcpdump`, `ngrep`, `iftop`, `nmap`, `socat`, `netcat-openbsd`, `websocat` |
| Connectivity | `iputils` (`ping`, `arping`, `tracepath`), `fping`, `mtr`, `traceroute`, `tcptraceroute`, `curl`, `wget` |
| Performance | `iperf3`, `apache2-utils` (`ab`), `htop`, `atop`, `procps` |
| Routing and firewalling | `iproute2` (`ip`, `ss`, `tc`), `bridge-utils`, `ethtool`, `iptables`, `nftables`, `ipset`, `ipvsadm`, `conntrack-tools` |
| Security and TLS | `openssl`, `openssh-client` |
| System and containers | `strace`, `lsof`, `lsblk`, `shadow`, `sudo`, `virt-what`, `skopeo`, `jq` |

The full list lives in the [`Dockerfile`](./Dockerfile). Images are built for `linux/amd64` and
`linux/arm64`, and signed with [cosign](https://github.com/sigstore/cosign):

```bash
cosign verify ghcr.io/mpepping/podshell:latest \
  --certificate-identity-regexp 'https://github.com/mpepping/podshell/.*' \
  --certificate-oidc-issuer https://token.actions.githubusercontent.com
```

## Extending at runtime

The package list is deliberately not exhaustive. Anything missing can be installed inside a running
podshell:

```bash
# binenv: binaries from their upstream GitHub releases
binenv update
binenv search kubectl
binenv install kubectl

# dbin: static binaries from the Toolpacks repository
dbin search yq
dbin install yq
dbin run --transparent gping
```

Both install into `$HOME` and are already on `$PATH`. Use `sudo` for anything that needs root, or
run the container as root with `securityContext.runAsUser: 0`.

## Building

```shell
❯ make
help                           This help.
build                          Build the image for the local platform
build-amd64                    Build the image for linux/amd64
build-arm64                    Build the image for linux/arm64
build-all                      Build multi-platform (see PLATFORMS), without pushing (mirrors CI)
lint                           Lint the Dockerfile (hadolint) and shell scripts (shellcheck)
push                           Push the image
pull                           Pull the image
clean                          Remove the image
start                          Start the container
stop                           Stop the container
test                           Test the container build
smoke                          Run the smoke test suite against the built image
runtime                        Show detected container runtime and OS
```

CI builds every pull request, runs [`test/smoke.sh`](./test/smoke.sh) against the resulting image
and, on `main` and tags, pushes signed multi-platform images to `ghcr.io/mpepping/podshell`.

## Contributing

Issues and PRs are welcome. When adding a tool, please:

- Explain why it is not redundant with something already in the image, and prefer `binenv`/`dbin`
  for niche or large tooling
- Add the package alphabetically to the `apk add` block in the [`Dockerfile`](./Dockerfile)
- Add it to the **Included tooling** table and, when useful, a **Troubleshooting recipes** snippet
- Add a check to [`test/smoke.sh`](./test/smoke.sh)
- Verify that `make build-all` succeeds for both `linux/amd64` and `linux/arm64`

## License

[MIT](./LICENSE)

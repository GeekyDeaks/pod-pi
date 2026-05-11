# pi-podman

Podman image and wrapper for running the `pi` agent with:

- `${HOME}/.pi` mounted read-only from the host
- a writable in-container `${HOME}/.pi` populated from that read-only mount at startup
- your current user mapped to the same UID/GID inside the container
- container root and other privileged IDs mapped through Podman's user namespace instead of to real host root

## Build

```bash
podman build -t localhost/pi-agent:latest .
```

## Run

```bash
chmod +x run-pi.sh
./run-pi.sh
```

Pass args through to `pi`:

```bash
./run-pi.sh --help
./run-pi.sh chat
```

## How the UID mapping works

The wrapper uses:

- `--userns=keep-id`
- `--user $(id -u):$(id -g)`

That keeps your current user mapped 1:1 while container root stays in the rootless user namespace backed by subordinate IDs, not host UID 0.

## Mounts

- `${HOME}/.pi -> /mnt/pi-config` as `ro`
- `/mnt/pi-config` copied into writable `/home/pi/.pi` on container startup
- `${PWD} -> /work` as the working directory
- writable tmpfs for `/home/pi` and `/tmp`

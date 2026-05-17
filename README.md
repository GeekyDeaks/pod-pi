# pi-podman

Podman images and wrappers for running the `pi` agent in sandboxed tool environments.

Images included:

- `Dockerfile.node` / `localhost/pi-agent:latest` — Node.js 22 environment
- `Dockerfile.golang` / `localhost/pi-agent-go:latest` — Go environment with Node/npm for `pi`
- `Dockerfile.android` / `localhost/pi-agent-android:latest` — Android app build environment with Node 22, OpenJDK 17, Android SDK platform tools, API 35, and build-tools 35.0.0

The wrappers run with:

- `${HOME}/.pi` mounted read-only from the host
- a writable in-container `${HOME}/.pi` populated from that read-only mount at startup
- your current user mapped to the same UID/GID inside the container
- container root and other privileged IDs mapped through Podman's user namespace instead of to real host root

## Build

```bash
./build-node
./build-go
./build-android
```

You can pass extra `podman build` arguments after the script name, or override the tag:

```bash
PI_PODMAN_IMAGE=localhost/custom-go:dev ./build-go --no-cache
```

## Run

Node image:

```bash
./pi-node
./sh-node
```

Go image:

```bash
./pi-go
./sh-go
```

Android image:

```bash
./pi-android
./sh-android
```

Pass args through to `pi`:

```bash
./pi-node --help
./pi-node chat
```

## How the UID mapping works

The wrapper uses:

- `--userns=keep-id`
- `--user $(id -u):$(id -g)`

That keeps your current user mapped 1:1 while container root stays in the rootless user namespace backed by subordinate IDs, not host UID 0.

## Mounts

- `${HOME}/.pi -> /mnt/pi-config` as `ro`
- `/mnt/pi-config` copied into writable `/home/pi/.pi` on container startup
- any symlink targets referenced from inside `${HOME}/.pi` and located outside that tree are also bind-mounted read-only at the same absolute path, so host-managed extension symlinks continue to resolve inside the container
- `${PWD} -> /work` as the working directory
- writable tmpfs for `/home/pi` and `/tmp`

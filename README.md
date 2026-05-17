# pi-podman

Podman image and wrappers for running the `pi` agent in a sandboxed, batteries-included tool environment.

The single image includes:

- Node.js 22 and npm for JavaScript/TypeScript projects and for `pi`
- Go 1.24
- OpenJDK 17
- Android command line tools
- Android SDK platform tools
- Android API 35
- Android build-tools 35.0.0
- common development utilities: git, curl, jq, ripgrep, Python 3, build-essential, tmux, unzip/zip, etc.

The wrappers run with:

- `${HOME}/.pi` mounted read-only from the host
- a writable in-container `${HOME}/.pi` populated from that read-only mount at startup
- your current user mapped to the same UID/GID inside the container
- container root and other privileged IDs mapped through Podman's user namespace instead of to real host root

## Build

```bash
./pod-build
```

You can pass extra `podman build` arguments after the script name, or override the tag:

```bash
PI_PODMAN_IMAGE=localhost/custom-pi-agent:dev ./pod-build --no-cache
```

## Run

Open a shell in the environment:

```bash
./pod
```

Run a command in the environment:

```bash
./pod pi
./pod pi --help
./pod go version
./pod npm --version
./pod sdkmanager --list
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

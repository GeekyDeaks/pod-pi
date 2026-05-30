# pi-podman

Podman image and wrappers for running the `pi` agent in a sandboxed, batteries-included tool environment.

The single image includes:

- Node.js 22 and npm for JavaScript/TypeScript projects and for `pi`
- Go 1.24
- OpenJDK 21
- Android command line tools
- Android SDK platform tools
- Android API 35
- Android build-tools 35.0.0
- common development utilities: git, curl, jq, ripgrep, Python 3, build-essential, tmux, unzip/zip, etc.

The default wrapper, `./pod`, runs with:

- a dedicated Podman volume mounted at `${HOME}/.pi` inside the container
- that volume initialized once from the host `${HOME}/.pi` using `./pod-init`
- no host `${HOME}/.pi` mount during normal runs, so the container pi environment can diverge from the host pi environment
- your current user mapped to the same UID/GID inside the container
- container root and other privileged IDs mapped through Podman's user namespace instead of to real host root

The volume name defaults to `pi-agent-pi` and can be overridden with `PI_PODMAN_PI_VOLUME`.

## Build

```bash
./pod-build
```

You can pass extra `podman build` arguments after the script name, or override the tag:

```bash
PI_PODMAN_IMAGE=localhost/custom-pi-agent:dev ./pod-build --no-cache
```

## Run

Initialize the dedicated pi volume from your host `${HOME}/.pi` once, after building the image:

```bash
./pod-init
```

Recreate it from the host later if needed. This deletes the existing volume first, so container-side pi state is replaced with a fresh copy of the host `${HOME}/.pi`:

```bash
./pod-init --force
```

Open a shell in the container environment:

```bash
./pod
```

Run a command in the container environment:

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

`./pod-init` mounts:

- `${HOME}/.pi -> /mnt/pi-config` as `ro`
- the Podman volume `${PI_PODMAN_PI_VOLUME:-pi-agent-pi} -> /home/pi/.pi` as `rw`

It copies `${HOME}/.pi` into the volume once. Normal `./pod` runs do not mount the host `${HOME}/.pi`.

`./pod` mounts:

- the Podman volume `${PI_PODMAN_PI_VOLUME:-pi-agent-pi} -> /home/pi/.pi` as `rw`
- `${PWD} -> /work` as the working directory
- writable tmpfs for `/home/pi` and `/tmp`

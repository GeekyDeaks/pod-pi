# pi-podman

Podman image and wrappers for running the `pi` agent in a sandboxed, batteries-included tool environment.

The images are split by toolchain:

- `localhost/pi-agent:base`, used by `./pod`
  - Node.js 22 and npm for JavaScript/TypeScript projects and for `pi`
  - common development utilities: git, curl, jq, ripgrep, Python 3, tmux, unzip/zip, Lightdash CLI, etc.
  - document/media inspection tools: ImageMagick, ExifTool, FFmpeg, MediaInfo, Poppler PDF tools, qpdf, Tesseract OCR, Pandoc, Graphviz, SQLite, XMLStarlet, zstd/xz/bzip2, and Python libraries for Pillow/OpenCV/OpenPyXL/BeautifulSoup/lxml/YAML
  - web lookup tools: ddgr, w3m, html2text, and Python requests/httpx
  - CSV/data wrangling tools: Miller (`mlr`), csvkit, SQLite, PostgreSQL client tools, and Python pandas/OpenPyXL
  - deep search/extraction tools: ripgrep-all (`rga`), fd, bat, universal-ctags, docx2txt, antiword/catdoc, odt2txt, unrtf, DjVu tools, 7zip, and unrar-free
  - a bundled `container-tools` pi skill documenting installed tools and common extraction/search workflows
- `localhost/pi-agent:go`, used by `./pod-go`
  - everything in `base`
  - Go 1.24 and build-essential
- `localhost/pi-agent:adk`, used by `./pod-adk`
  - everything in `base`
  - OpenJDK 21, Gradle, Android command line tools, Android SDK platform tools, Android API 35, and Android build-tools 35.0.0

The default wrapper, `./pod`, runs with:

- a dedicated Podman volume mounted at `${HOME}/.pi` inside the container
- that volume initialized once from the host `${HOME}/.pi` using `./pod-init`
- no host `${HOME}/.pi` mount during normal runs, so the container pi environment can diverge from the host pi environment
- your current user mapped to the same UID/GID inside the container
- container root and other privileged IDs mapped through Podman's user namespace instead of to real host root

The volume name defaults to `pi-agent-pi` and can be overridden with `PI_PODMAN_PI_VOLUME`.

## Build

```bash
./pod-build          # builds localhost/pi-agent:base
./pod-build go       # builds localhost/pi-agent:go
./pod-build adk      # builds localhost/pi-agent:adk
./pod-build all      # builds all images
```

You can pass extra `podman build` arguments after the image target, or override the image prefix:

```bash
PI_PODMAN_IMAGE_PREFIX=localhost/custom-pi-agent ./pod-build all --no-cache
```

Tool versions are pinned/configured in `Dockerfile` `ENV` values, including `PI_CODING_AGENT_VERSION` and `LIGHTDASH_CLI_VERSION`. To update pi or Lightdash CLI, change the relevant value and rebuild, preferably without cache:

```bash
./pod-build all --pull --no-cache
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
./pod npm --version
./pod-go go version
./pod-adk sdkmanager --list
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

If `${PWD}/.env` exists, `./pod` also passes it to Podman with `--env-file`. The wrapper still explicitly sets `HOME=/home/pi` after loading the env file, so project `.env` files cannot override the container home directory.

# pi-podman

Podman image and wrappers for running the `pi` agent in a sandboxed, batteries-included tool environment.

The images are split by toolchain:

- `localhost/pi-agent:base`, used by `./pod`
  - Node.js 22 and npm for JavaScript/TypeScript projects and for `pi`
  - common development utilities: git, curl, jq, ripgrep, Python 3, tmux, unzip/zip, Lightdash CLI, etc.
  - document/media inspection tools: ImageMagick, ExifTool, FFmpeg, MediaInfo, Poppler PDF tools, qpdf, Tesseract OCR, Pandoc, Graphviz, SQLite, XMLStarlet, zstd/xz/bzip2, and Python libraries for Pillow/OpenCV/OpenPyXL/BeautifulSoup/lxml/YAML
  - web lookup tools: ddgr, w3m, html2text, and Python requests/httpx
  - rendered-page analysis: an auto-loaded `rendered_page` extension backed by Playwright and bundled headless Chromium for JavaScript pages, post-render DOM inspection, and screenshots
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

- a dedicated `pi-agent-pi` Podman volume mounted at `/home/pi/.pi` inside the container
- no access to the host's `${HOME}/.pi`; container Pi state starts independently and persists in the volume
- repository-provided agent assets merged into the volume explicitly with `./pod-init`
- your current user mapped to the same UID/GID inside the container
- container root and other privileged IDs mapped through Podman's user namespace instead of to real host root

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

Tool versions are pinned/configured in `Dockerfile` `ENV` values, including `PI_CODING_AGENT_VERSION`, `LIGHTDASH_CLI_VERSION`, and `PLAYWRIGHT_VERSION`. To update pi, Lightdash CLI, or Playwright, change the relevant value and rebuild, preferably without cache:

```bash
./pod-build all --pull --no-cache
```

## Run

After building the base image, create the dedicated Pi volume, merge the bundled agent assets into it, and install the pinned `@tintinweb/pi-subagents` package:

```bash
./pod-init
```

The package version defaults to `0.19.0` and can be overridden when initializing:

```bash
PI_SUBAGENTS_VERSION=0.19.0 ./pod-init
```

Run `./pod-init` again after rebuilding to update the assets and reconcile the package installation. Initialization overwrites matching bundled files but retains other files in `.pi/agent` and preserves all other Pi state. To start completely fresh, remove the volume and initialize it again:

```bash
podman volume rm pi-agent-pi
./pod-init
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

`./pod-init` mounts the `pi-agent-pi` Podman volume at `/home/pi/.pi` and merges the agent assets bundled in the image into `/home/pi/.pi/agent`. It never reads the host's `${HOME}/.pi`.

`./pod` mounts:

- the `pi-agent-pi` Podman volume at `/home/pi/.pi` as `rw`
- `${PWD} -> /work` as the working directory
- writable tmpfs for `/home/pi` and `/tmp`

If `${PWD}/.env` exists, `./pod` also passes it to Podman with `--env-file`. The wrapper still explicitly sets `HOME=/home/pi` after loading the env file, so project `.env` files cannot override the container home directory.

#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/home/pi}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/.cache}"
export TMPDIR="${TMPDIR:-/tmp}"

mkdir -p "$HOME" "$XDG_CACHE_HOME" "$TMPDIR" "$HOME/.pi"

if [[ -d /mnt/pi-config ]]; then
  cp -a /mnt/pi-config/. "$HOME/.pi/"
fi

if [[ "$#" -eq 0 ]]; then
  set -- pi
elif [[ "$1" == -* ]]; then
  set -- pi "$@"
fi

exec "$@"

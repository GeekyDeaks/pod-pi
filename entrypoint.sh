#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/home/pi}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/.cache}"
export TMPDIR="${TMPDIR:-/tmp}"

mkdir -p "$HOME" "$XDG_CACHE_HOME" "$TMPDIR" "$HOME/.pi"

if [[ -d /usr/local/share/pi-agent ]]; then
  mkdir -p "$HOME/.pi/agent"
  cp -a /usr/local/share/pi-agent/. "$HOME/.pi/agent/"
fi

if [[ "$#" -eq 0 ]]; then
  set -- pi
elif [[ "$1" == -* ]]; then
  set -- pi "$@"
fi

exec "$@"

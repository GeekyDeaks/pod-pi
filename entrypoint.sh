#!/usr/bin/env bash
set -euo pipefail

export HOME="${HOME:-/home/pi}"
export XDG_CACHE_HOME="${XDG_CACHE_HOME:-/tmp/.cache}"
export TMPDIR="${TMPDIR:-/tmp}"

mkdir -p "$HOME" "$XDG_CACHE_HOME" "$TMPDIR" "$HOME/.pi"

if [[ -d /usr/local/share/pi-agent/skills ]]; then
  mkdir -p "$HOME/.pi/agent/skills"
  cp -a /usr/local/share/pi-agent/skills/. "$HOME/.pi/agent/skills/"
fi

if [[ -d /usr/local/share/pi-agent/extensions ]]; then
  mkdir -p "$HOME/.pi/agent/extensions"
  cp -a /usr/local/share/pi-agent/extensions/. "$HOME/.pi/agent/extensions/"
fi

if [[ "$#" -eq 0 ]]; then
  set -- pi
elif [[ "$1" == -* ]]; then
  set -- pi "$@"
fi

exec "$@"

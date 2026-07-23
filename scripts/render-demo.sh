#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if ! command -v magick >/dev/null 2>&1; then
  printf 'ImageMagick 7 (magick command) is required to render the terminal demo.\n' >&2
  exit 1
fi

if ! command -v resvg >/dev/null 2>&1; then
  printf 'resvg 0.47 or newer is required to rasterize the terminal demo.\n' >&2
  exit 1
fi

render_dir="$(mktemp -d)"
trap 'rm -rf "$render_dir"' EXIT

resvg "$ROOT_DIR/assets/source/terminal-demo.svg" "$render_dir/check.png"
resvg "$ROOT_DIR/assets/source/terminal-demo-compare.svg" "$render_dir/compare.png"
resvg "$ROOT_DIR/assets/source/terminal-demo-boundary.svg" "$render_dir/boundary.png"

magick \
  -delay 800 "$render_dir/check.png" \
  -delay 800 "$render_dir/compare.png" \
  -delay 800 "$render_dir/boundary.png" \
  -loop 0 -layers Optimize "$ROOT_DIR/assets/terminal-demo.gif"

dimensions="$(magick identify -format '%wx%h' "$ROOT_DIR/assets/terminal-demo.gif[0]")"
frames="$(magick identify "$ROOT_DIR/assets/terminal-demo.gif" | wc -l | tr -d ' ')"
bytes="$(wc -c <"$ROOT_DIR/assets/terminal-demo.gif" | tr -d ' ')"

if [ "$dimensions" != "1200x675" ] || [ "$frames" != "3" ] || [ "$bytes" -gt 900000 ]; then
  printf 'Unexpected terminal demo output: %s, %s frames, %s bytes\n' \
    "$dimensions" "$frames" "$bytes" >&2
  exit 1
fi

printf 'Rendered fixture-only terminal demo in assets/terminal-demo.gif.\n'

#!/usr/bin/env bash
# Regenerate every favicon artefact from tools/logo.html.
#
#   ./tools/build-icons.sh
#
# Chrome clamps windows below roughly 400px, so small sizes are downsampled
# from a native 512px render rather than screenshotted directly.

set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$root"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

./tools/render.sh tools/logo.html 512 512 icon-512.png

for size in 192 180 96 48 32 16; do
  sips -z "$size" "$size" icon-512.png --out "${work}/${size}.png" >/dev/null
done

cp "${work}/192.png" icon-192.png
cp "${work}/180.png" apple-touch-icon.png

python3 tools/make-ico.py favicon.ico "${work}/16.png" "${work}/32.png" "${work}/48.png"

echo "icons rebuilt: favicon.ico, favicon.svg, icon-192.png, icon-512.png, apple-touch-icon.png"

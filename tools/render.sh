#!/usr/bin/env bash
# Rasterise an HTML/SVG source file to PNG with headless Chrome, so the artwork
# renders with the same webfonts and gradient engine the live site uses.
#
#   ./tools/render.sh <source> <width> <height> <output.png>
#
# Chrome's background updater keeps the process alive well after the screenshot
# is on disk, so we launch it detached and reap it once the file stops growing.

set -uo pipefail

CHROME="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

src="$1"
width="$2"
height="$3"
out="$4"

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
target="${root}/${out}"
profile="$(mktemp -d)"

case "$src" in
  http://*|https://*) url="$src" ;;
  *)                  url="file://${root}/${src}" ;;
esac

rm -f "$target"

"$CHROME" \
  --headless=new \
  --disable-gpu \
  --no-first-run \
  --no-default-browser-check \
  --hide-scrollbars \
  --force-device-scale-factor=1 \
  --user-data-dir="$profile" \
  --window-size="${width},${height}" \
  --screenshot="$target" \
  "$url" >/dev/null 2>&1 &
chrome_pid=$!

size=0
for _ in $(seq 1 60); do
  sleep 0.5
  [ -f "$target" ] || continue
  now=$(wc -c <"$target")
  # Two consecutive equal, non-zero readings means the write finished.
  if [ "$now" -gt 0 ] && [ "$now" -eq "$size" ]; then break; fi
  size="$now"
done

kill "$chrome_pid" 2>/dev/null
wait "$chrome_pid" 2>/dev/null
rm -rf "$profile"

if [ ! -s "$target" ]; then
  echo "failed to render ${out}" >&2
  exit 1
fi

echo "rendered ${out} (${width}x${height}, $(wc -c <"$target" | tr -d ' ') bytes)"

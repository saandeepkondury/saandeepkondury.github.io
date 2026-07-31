#!/usr/bin/env python3
"""Pack PNGs into a multi-resolution .ico.

  python3 tools/make-ico.py favicon.ico 16.png 32.png 48.png

Entries are stored as embedded PNGs, which every browser in use today reads.
"""

import struct
import sys


def main() -> int:
    out, sources = sys.argv[1], sys.argv[2:]
    if not sources:
        print("usage: make-ico.py <out.ico> <png> [png ...]", file=sys.stderr)
        return 1

    images = []
    for path in sources:
        data = open(path, "rb").read()
        if data[:8] != b"\x89PNG\r\n\x1a\n":
            raise SystemExit(f"{path} is not a PNG")
        width, height = struct.unpack(">II", data[16:24])
        images.append((width, height, data))

    header = struct.pack("<HHH", 0, 1, len(images))
    offset = len(header) + 16 * len(images)

    entries, blobs = b"", b""
    for width, height, data in images:
        entries += struct.pack(
            "<BBBBHHII",
            width if width < 256 else 0,
            height if height < 256 else 0,
            0,  # palette size
            0,  # reserved
            1,  # colour planes
            32,  # bits per pixel
            len(data),
            offset,
        )
        blobs += data
        offset += len(data)

    with open(out, "wb") as handle:
        handle.write(header + entries + blobs)

    sizes = ", ".join(f"{w}x{h}" for w, h, _ in images)
    print(f"wrote {out} ({sizes})")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

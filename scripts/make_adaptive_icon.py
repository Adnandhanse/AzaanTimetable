#!/usr/bin/env python3
"""Prepares an adaptive-icon foreground from any square source image.

THE PROBLEM THIS SOLVES:

Android's adaptive icons (API 26+) place the foreground drawable on a
108x108dp canvas, then apply a mask (circle, squircle, rounded square - the
shape varies by launcher and OEM). Content is only GUARANTEED visible if it
sits inside a centered "safe zone" roughly 66% of the canvas - everything
outside that gets cropped by some launcher's mask, even if it looks fine on
your own phone's launcher specifically.

A source image whose content runs edge-to-edge (as `app_icon_foreground.png`
did before this script existed - fully opaque, zero transparent margin) gets
its border and any text near the edge cut off. That was this app's actual
bug: the icon wasn't "too big" in file size, its VISIBLE CONTENT was drawn
too close to the edge for any adaptive mask to leave alone.

THE FIX:

Shrink the source image to `SAFE_ZONE_SCALE` of a new, fully transparent
square canvas, centered. The result is the same artwork, just with a
transparent margin around it wide enough that every launcher's mask crops
into empty space instead of the logo.

USAGE:

    python3 scripts/make_adaptive_icon.py <source_image> [output_path]

Run this on ANY new icon artwork before wiring it up in pubspec.yaml's
`adaptive_icon_foreground` - it does not need to already be padded or
transparent; this script handles that regardless of what comes in. Default
output is assets/icon/app_icon_foreground.png, matching the pubspec.yaml
config already pointing there. After running it, regenerate the actual
launcher icons with:

    flutter pub run flutter_launcher_icons

Requires Pillow: pip install pillow --break-system-packages
"""

import sys
from pathlib import Path

from PIL import Image

# Matches the percentage already documented in pubspec.yaml's
# adaptive_icon_foreground comment - the two are meant to stay in sync.
SAFE_ZONE_SCALE = 0.66

# 1024 is comfortably above every density Android generates from this
# (up to xxxhdpi at 432px), so nothing gets upscaled and blurry.
CANVAS_SIZE = 1024

DEFAULT_OUTPUT = Path("assets/icon/app_icon_foreground.png")


def make_adaptive_icon(source_path: Path, output_path: Path) -> None:
    source = Image.open(source_path).convert("RGBA")

    # Square first - a non-square source would otherwise get stretched
    # rather than cropped, distorting the artwork instead of just centering
    # it. Crop to the smaller dimension, centered, rather than guess intent.
    if source.width != source.height:
        side = min(source.width, source.height)
        left = (source.width - side) // 2
        top = (source.height - side) // 2
        source = source.crop((left, top, left + side, top + side))

    content_size = round(CANVAS_SIZE * SAFE_ZONE_SCALE)
    resized = source.resize((content_size, content_size), Image.LANCZOS)

    canvas = Image.new("RGBA", (CANVAS_SIZE, CANVAS_SIZE), (0, 0, 0, 0))
    offset = (CANVAS_SIZE - content_size) // 2
    canvas.paste(resized, (offset, offset), resized)

    output_path.parent.mkdir(parents=True, exist_ok=True)
    canvas.save(output_path)
    print(f"Wrote {output_path} ({CANVAS_SIZE}x{CANVAS_SIZE}, "
          f"content at {int(SAFE_ZONE_SCALE * 100)}% / {content_size}px, "
          f"centered with a transparent margin).")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        print(__doc__)
        sys.exit(1)

    src = Path(sys.argv[1])
    out = Path(sys.argv[2]) if len(sys.argv) > 2 else DEFAULT_OUTPUT
    make_adaptive_icon(src, out)

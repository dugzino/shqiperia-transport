#!/usr/bin/env python3
"""Simple full-bleed app icon: Albanian red + eagle. Fills the Android circle."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
EAGLE_SRC = ROOT / "store/play/source/icon-eagle-source.jpg"
RES = ROOT / "android/app/src/main/res"
PLAY = ROOT / "store/play"

# Official-looking Albanian red. Full-bleed so the launcher circle is solid.
RED = (228, 30, 36)

# Adaptive-icon canvas is 108dp; the safe zone is the center 72dp (2/3).
# Eagle is sized to that inner disc so it never clips on a circle/squircle.
SIZE = 1024
EAGLE_RATIO = 0.56

MIPMAPS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Foreground layer recommended 108dp → 4x master, then scaled per density.
FG_MIPMAPS = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}


def extract_eagle() -> Image.Image:
    src = Image.open(EAGLE_SRC).convert("RGB")
    w, h = src.size
    hub = src.crop((int(w * 0.38), int(h * 0.38), int(w * 0.62), int(h * 0.62)))
    arr = np.array(hub)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    yy, xx = np.ogrid[: hub.height, : hub.width]
    cy, cx = hub.height / 2, hub.width / 2
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    eagle = (r < 55) & (g < 45) & (b < 45) & (dist < min(cx, cy) * 0.80)
    ys, xs = np.where(eagle)
    pad = 8
    box = (
        max(int(xs.min()) - pad, 0),
        max(int(ys.min()) - pad, 0),
        min(int(xs.max()) + pad + 1, hub.width),
        min(int(ys.max()) + pad + 1, hub.height),
    )
    local = eagle[box[1] : box[3], box[0] : box[2]]
    out = np.zeros((local.shape[0], local.shape[1], 4), dtype=np.uint8)
    out[local] = (18, 18, 18, 255)
    return Image.fromarray(out, "RGBA")


def fit_in(im: Image.Image, box: int) -> Image.Image:
    scale = box / max(im.width, im.height)
    size = (max(1, int(im.width * scale)), max(1, int(im.height * scale)))
    return im.resize(size, Image.Resampling.LANCZOS)


def compose_full() -> Image.Image:
    eagle = fit_in(extract_eagle(), int(SIZE * EAGLE_RATIO))
    canvas = Image.new("RGB", (SIZE, SIZE), RED)
    x = (SIZE - eagle.width) // 2
    y = (SIZE - eagle.height) // 2
    canvas.paste(eagle, (x, y), eagle)
    return canvas


def compose_foreground() -> Image.Image:
    """Transparent layer; eagle sits in the adaptive-icon safe zone."""
    eagle = fit_in(extract_eagle(), int(SIZE * EAGLE_RATIO))
    canvas = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    x = (SIZE - eagle.width) // 2
    y = (SIZE - eagle.height) // 2
    canvas.paste(eagle, (x, y), eagle)
    return canvas


def write_xml() -> None:
    (RES / "values" / "ic_launcher_background.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#E41E24</color>
</resources>
"""
    )
    anydpi = RES / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    adaptive = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""
    (anydpi / "ic_launcher.xml").write_text(adaptive)
    (anydpi / "ic_launcher_round.xml").write_text(adaptive)


def main() -> None:
    full = compose_full()
    fg = compose_foreground()

    PLAY.mkdir(parents=True, exist_ok=True)
    full.save(PLAY / "icon-1024.png")
    full.resize((512, 512), Image.Resampling.LANCZOS).save(PLAY / "icon-512.png")
    full.save(PLAY / "source" / "icon-master.jpg", quality=95)

    for folder, size in MIPMAPS.items():
        dest = RES / folder
        dest.mkdir(parents=True, exist_ok=True)
        icon = full.resize((size, size), Image.Resampling.LANCZOS)
        icon.save(dest / "ic_launcher.png")
        icon.save(dest / "ic_launcher_round.png")

    for folder, size in FG_MIPMAPS.items():
        dest = RES / folder
        dest.mkdir(parents=True, exist_ok=True)
        fg.resize((size, size), Image.Resampling.LANCZOS).save(
            dest / "ic_launcher_foreground.png"
        )

    write_xml()
    print("wrote simple full-bleed icon")


if __name__ == "__main__":
    main()

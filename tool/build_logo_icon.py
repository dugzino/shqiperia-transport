#!/usr/bin/env python3
"""Compose the app icon from the user's wheel silhouette + Albanian eagle fragment."""

from __future__ import annotations

from pathlib import Path

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parents[1]
SILHOUETTE = ROOT / "store/play/source/icon-silhouette-square.png"
EAGLE_SRC = ROOT / "store/play/source/icon-eagle-source.jpg"
OUT_MASTER = ROOT / "store/play/source/icon-master-v2.png"
OUT_512 = ROOT / "store/play/icon-512.png"
ANDROID_RES = ROOT / "android/app/src/main/res"

CREAM = (247, 236, 214)
RED = (227, 30, 36)  # Albanian flag red
TIRE = (18, 18, 18)
RIM = (212, 168, 58)
TREAD = (40, 40, 40)

MIPMAPS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def fit_circle(mask: np.ndarray) -> tuple[float, float, float]:
    h, w = mask.shape
    tops = []
    rights = []
    for x in range(w):
        col = np.where(mask[:, x])[0]
        if col.size:
            tops.append((x, int(col.min())))
    for y in range(h):
        row = np.where(mask[y])[0]
        if row.size:
            rights.append((int(row.max()), y))
    pts = [(x, y) for x, y in tops if x > w * 0.35 and y < h * 0.55]
    pts += [(x, y) for x, y in rights if y < h * 0.7 and x > w * 0.5]
    pts_a = np.array(pts, dtype=float)
    x, y = pts_a[:, 0], pts_a[:, 1]
    a = np.column_stack([x, y, np.ones(len(x))])
    b = -(x**2 + y**2)
    d, e, f = np.linalg.lstsq(a, b, rcond=None)[0]
    cx, cy = -d / 2, -e / 2
    r = float(np.sqrt(cx**2 + cy**2 - f))
    return cx, cy, r


def extract_eagle() -> Image.Image:
    src = Image.open(EAGLE_SRC).convert("RGB")
    w, h = src.size
    hub = src.crop((int(w * 0.38), int(h * 0.38), int(w * 0.62), int(h * 0.62)))
    arr = np.array(hub)
    r, g, b = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2]
    yy, xx = np.ogrid[: hub.height, : hub.width]
    cy, cx = hub.height / 2, hub.width / 2
    dist = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    # Ignore the hub outline ring; keep only the bird.
    eagle = (r < 55) & (g < 45) & (b < 45) & (dist < min(cx, cy) * 0.82)
    ys, xs = np.where(eagle)
    pad = 6
    box = (
        max(int(xs.min()) - pad, 0),
        max(int(ys.min()) - pad, 0),
        min(int(xs.max()) + pad + 1, hub.width),
        min(int(ys.max()) + pad + 1, hub.height),
    )
    local = eagle[box[1] : box[3], box[0] : box[2]]
    c = np.zeros((local.shape[0], local.shape[1], 4), dtype=np.uint8)
    c[local] = (12, 12, 12, 255)
    eagle_im = Image.fromarray(c, "RGBA")
    ew, eh = eagle_im.size
    # Upper-left of the official eagle: left head + left wing.
    frag = eagle_im.crop((0, 0, int(ew * 0.58), int(eh * 0.54)))
    # Keep the bird solid; only feather the chopped bottom-right edge.
    fa = np.array(frag)
    fh, fw = fa.shape[:2]
    gy, gx = np.ogrid[:fh, :fw]
    t = (gx / max(fw - 1, 1) + gy / max(fh - 1, 1)) / 2.0
    fade = np.clip((0.88 - t) / 0.18, 0.0, 1.0)
    fa[:, :, 3] = (fa[:, :, 3].astype(np.float32) * fade).astype(np.uint8)
    return Image.fromarray(fa, "RGBA")


def compose() -> Image.Image:
    sil = Image.open(SILHOUETTE).convert("L")
    mask = np.array(sil) < 40
    cx, cy, radius = fit_circle(mask)
    w, h = sil.size

    canvas = Image.new("RGBA", (w, h), (*CREAM, 255))
    draw = ImageDraw.Draw(canvas)

    # Full silhouette as the black mark (blobs + wheel body).
    sil_rgba = Image.new("RGBA", (w, h), (*TIRE, 255))
    alpha = Image.fromarray((mask * 255).astype(np.uint8), "L")
    sil_rgba.putalpha(alpha)
    canvas.alpha_composite(sil_rgba)

    # Wheel construction inside the fitted circle.
    tire_inner = radius * 0.72
    rim_inner = radius * 0.64
    hub_r = radius * 0.60

    def circ(rr: float, fill) -> None:
        draw.ellipse(
            (cx - rr, cy - rr, cx + rr, cy + rr),
            fill=fill,
        )

    # Subtle tread rings in the tire band.
    circ(radius * 0.96, TREAD)
    circ(radius * 0.90, TIRE)
    circ(radius * 0.84, TREAD)
    circ(tire_inner, TIRE)
    circ(rim_inner, RIM)
    circ(hub_r, RED)

    # Clip wheel paints back to the silhouette so blobs stay clean.
    # (circle paint can spill; mask it)
    painted = canvas.copy()
    base = Image.new("RGBA", (w, h), (*CREAM, 255))
    base.alpha_composite(sil_rgba)
    # Only replace pixels that are inside the circle AND inside the silhouette.
    yy, xx = np.ogrid[:h, :w]
    in_circle = (xx - cx) ** 2 + (yy - cy) ** 2 <= (radius + 0.5) ** 2
    mix = np.array(painted)
    dest = np.array(base)
    dest[in_circle] = mix[in_circle]
    canvas = Image.fromarray(dest, "RGBA")
    draw = ImageDraw.Draw(canvas)

    eagle = extract_eagle()
    # Close-up of the fragment sitting in the upper-left of the hub.
    target = int(hub_r * 1.38)
    eagle = eagle.resize((target, int(target * eagle.height / eagle.width)), Image.Resampling.LANCZOS)
    ex = int(cx - hub_r * 0.98)
    ey = int(cy - hub_r * 0.96)
    # Clip eagle to the hub disk.
    hub_mask = Image.new("L", (w, h), 0)
    ImageDraw.Draw(hub_mask).ellipse(
        (cx - hub_r + 2, cy - hub_r + 2, cx + hub_r - 2, cy + hub_r - 2),
        fill=255,
    )
    layer = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    layer.paste(eagle, (ex, ey), eagle)
    layer.putalpha(
        Image.fromarray(
            np.minimum(np.array(layer.split()[-1]), np.array(hub_mask)),
            "L",
        )
    )
    canvas.alpha_composite(layer)

    # Soft inner hub ring so the eagle sits on a wheel, not a sticker.
    ring = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    rd = ImageDraw.Draw(ring)
    rd.ellipse(
        (cx - hub_r, cy - hub_r, cx + hub_r, cy + hub_r),
        outline=(90, 8, 10, 180),
        width=3,
    )
    canvas.alpha_composite(ring)

    return canvas.filter(ImageFilter.SMOOTH_MORE)


def main() -> None:
    icon = compose()
    # Flatten to cream RGB and export sizes.
    rgb = Image.new("RGB", icon.size, CREAM)
    rgb.paste(icon, mask=icon.split()[-1])
    master = rgb.resize((1024, 1024), Image.Resampling.LANCZOS)
    master.save(OUT_MASTER)
    master.save(ROOT / "store/play/icon-1024.png")
    small = master.resize((512, 512), Image.Resampling.LANCZOS)
    small.save(OUT_512)
    # Also become the new source master used by the Play packager.
    master.convert("RGB").save(ROOT / "store/play/source/icon-master.jpg", quality=95)
    for folder, size in MIPMAPS.items():
        dest = ANDROID_RES / folder / "ic_launcher.png"
        master.resize((size, size), Image.Resampling.LANCZOS).save(dest)
    print("wrote", OUT_MASTER, OUT_512)


if __name__ == "__main__":
    main()

#!/usr/bin/env python3
"""Build Google Play listing assets and Android launcher mipmaps."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "store" / "play"
ICON_SRC = OUT / "source" / "icon-master.jpg"
BANNER_SRC = OUT / "source" / "banner-bg.jpg"
MAP_SRC = OUT / "source" / "map-bg.jpg"
STREET_SRC = OUT / "source" / "street-bg.jpg"
ANDROID_RES = ROOT / "android" / "app" / "src" / "main" / "res"

PRIMARY = (11, 61, 145)
PRIMARY_LIGHT = (30, 91, 184)
SECONDARY = (232, 93, 4)
CREAM = (247, 236, 214)
INK = (17, 24, 39)
MUTED = (75, 85, 99)
WHITE = (255, 255, 255)

FONT_EXTRABOLD = "/usr/share/fonts/noto/NotoSans-ExtraBold.ttf"
FONT_BOLD = "/usr/share/fonts/noto/NotoSans-Bold.ttf"
FONT_SEMI = "/usr/share/fonts/noto/NotoSans-SemiBold.ttf"
FONT_MED = "/usr/share/fonts/noto/NotoSans-Medium.ttf"

MIPMAPS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def flatten_rgb(path: Path, fill: tuple[int, int, int] = CREAM) -> Image.Image:
    im = Image.open(path).convert("RGBA")
    bg = Image.new("RGB", im.size, fill)
    bg.paste(im, mask=im.split()[-1])
    return bg


def fit(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    return ImageOps_fit(im, size)


def ImageOps_fit(im: Image.Image, size: tuple[int, int]) -> Image.Image:
    src_ratio = im.width / im.height
    dst_ratio = size[0] / size[1]
    if src_ratio > dst_ratio:
        new_h = im.height
        new_w = int(new_h * dst_ratio)
        left = (im.width - new_w) // 2
        im = im.crop((left, 0, left + new_w, new_h))
    else:
        new_w = im.width
        new_h = int(new_w / dst_ratio)
        top = (im.height - new_h) // 2
        im = im.crop((0, top, new_w, top + new_h))
    return im.resize(size, Image.Resampling.LANCZOS)


def crop_inner_frame(im: Image.Image, pad: int = 10) -> Image.Image:
    return im.crop((pad, pad, im.width - pad, im.height - pad))


def round_icon(im: Image.Image, radius: int | None = None) -> Image.Image:
    icon = im.convert("RGBA")
    if radius is None:
        radius = max(24, icon.width // 6)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle(
        (0, 0, icon.width, icon.height),
        radius=radius,
        fill=255,
    )
    icon.putalpha(mask)
    return icon


def rounded_rect(
    draw: ImageDraw.ImageDraw,
    box: tuple[int, int, int, int],
    radius: int,
    fill: tuple[int, ...],
) -> None:
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def draw_centered_text(
    draw: ImageDraw.ImageDraw,
    text: str,
    y: int,
    fnt: ImageFont.FreeTypeFont,
    fill: tuple[int, int, int],
    canvas_w: int,
) -> int:
    bbox = draw.textbbox((0, 0), text, font=fnt)
    tw = bbox[2] - bbox[0]
    draw.text(((canvas_w - tw) / 2, y), text, font=fnt, fill=fill)
    return bbox[3] - bbox[1]


def wrap_text(text: str, fnt: ImageFont.FreeTypeFont, max_width: int) -> list[str]:
    words = text.split()
    lines: list[str] = []
    current = ""
    dummy = ImageDraw.Draw(Image.new("RGB", (1, 1)))
    for word in words:
        trial = word if not current else f"{current} {word}"
        width = dummy.textbbox((0, 0), trial, font=fnt)[2]
        if width <= max_width:
            current = trial
        else:
            if current:
                lines.append(current)
            current = word
    if current:
        lines.append(current)
    return lines


def save_rgb(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    rgb = im.convert("RGB")
    rgb.save(path, format="PNG", optimize=True)


def build_icon() -> Image.Image:
    icon = flatten_rgb(ICON_SRC)
    icon_512 = icon.resize((512, 512), Image.Resampling.LANCZOS)
    save_rgb(icon_512, OUT / "icon-512.png")
    save_rgb(icon_512, OUT / "icon-1024.png")
    big = icon.resize((1024, 1024), Image.Resampling.LANCZOS)
    save_rgb(big, OUT / "icon-1024.png")

    for folder, size in MIPMAPS.items():
        dest = ANDROID_RES / folder / "ic_launcher.png"
        resized = icon.resize((size, size), Image.Resampling.LANCZOS)
        save_rgb(resized, dest)
    return icon_512


def build_feature(icon: Image.Image) -> None:
    banner = flatten_rgb(BANNER_SRC, fill=PRIMARY)
    banner = crop_inner_frame(banner, 18)
    art = ImageOps_fit(banner, (1024, 500))

    # Soft navy veil on the right so type stays readable.
    veil = Image.new("RGBA", art.size, (0, 0, 0, 0))
    vdraw = ImageDraw.Draw(veil)
    for x in range(380, 1024):
        t = (x - 380) / (1024 - 380)
        alpha = int(30 + 120 * t)
        vdraw.line([(x, 0), (x, 500)], fill=(11, 41, 96, alpha))
    composed = art.convert("RGBA")
    composed = Image.alpha_composite(composed, veil)

    icon_sm = round_icon(icon.resize((188, 188), Image.Resampling.LANCZOS), radius=40)
    shadow = Image.new("RGBA", (220, 220), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle((10, 14, 210, 210), radius=44, fill=(0, 0, 0, 70))
    shadow = shadow.filter(ImageFilter.GaussianBlur(8))
    composed.paste(shadow, (48, 48), shadow)
    composed.paste(icon_sm, (56, 48), icon_sm)

    draw = ImageDraw.Draw(composed)
    title = font(FONT_EXTRABOLD, 46)
    sub = font(FONT_SEMI, 22)
    draw.text((270, 72), "Soar Albania", font=title, fill=WHITE)
    lines = wrap_text(
        "Buses & routes across Kosova and Albania",
        sub,
        700,
    )
    y = 140
    for line in lines:
        draw.text((272, y), line, font=sub, fill=(226, 232, 240))
        y += 32

    save_rgb(composed, OUT / "feature-graphic-1024x500.png")


def phone_canvas(bg_path: Path) -> Image.Image:
    bg = flatten_rgb(bg_path, fill=PRIMARY)
    return ImageOps_fit(bg, (1080, 1920))


def add_top_scrim(im: Image.Image, height: int = 780, color=(11, 41, 96)) -> Image.Image:
    overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    for y in range(height):
        t = 1 - (y / height)
        alpha = int(210 * t)
        draw.line([(0, y), (im.width, y)], fill=(*color, alpha))
    return Image.alpha_composite(im.convert("RGBA"), overlay)


def draw_card(
    base: Image.Image,
    box: tuple[int, int, int, int],
    title: str,
    body: str,
    badge: str | None = None,
) -> None:
    overlay = Image.new("RGBA", base.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(overlay)
    rounded_rect(draw, box, 36, (255, 255, 255, 255))
    x0, y0, x1, _y1 = box
    title_f = font(FONT_EXTRABOLD, 36)
    body_f = font(FONT_MED, 28)
    badge_f = font(FONT_BOLD, 24)
    draw.text((x0 + 36, y0 + 28), title, font=title_f, fill=INK)
    if badge:
        bb = draw.textbbox((0, 0), badge, font=badge_f)
        bw = bb[2] - bb[0] + 28
        bh = bb[3] - bb[1] + 16
        bx1 = x1 - 36
        bx0 = bx1 - bw
        by0 = y0 + 32
        rounded_rect(draw, (bx0, by0, bx1, by0 + bh), 16, (*SECONDARY, 255))
        draw.text((bx0 + 14, by0 + 6), badge, font=badge_f, fill=WHITE)
    y = y0 + 86
    for line in wrap_text(body, body_f, x1 - x0 - 72):
        draw.text((x0 + 36, y), line, font=body_f, fill=MUTED)
        y += 38
    base.alpha_composite(overlay)


def screenshot_nearby(icon: Image.Image) -> Image.Image:
    im = add_top_scrim(phone_canvas(STREET_SRC))
    draw = ImageDraw.Draw(im)
    ic = round_icon(icon.resize((220, 220), Image.Resampling.LANCZOS), 44)
    im.paste(ic, (430, 90), ic)
    footer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(footer).rectangle((0, 1120, 1080, 1920), fill=(247, 248, 250, 255))
    im.alpha_composite(footer)
    title = font(FONT_EXTRABOLD, 64)
    sub = font(FONT_SEMI, 32)
    y = 340
    for line in wrap_text("See the next bus near you", title, 920):
        draw_centered_text(draw, line, y, title, WHITE, 1080)
        y += 78
    y += 8
    for line in wrap_text(
        "Allow location to get nearby stops and the next departure.",
        sub,
        880,
    ):
        draw_centered_text(draw, line, y, sub, (226, 232, 240), 1080)
        y += 44
    draw_card(
        im,
        (72, 1180, 1008, 1410),
        "Sheshi Skënderbeu",
        "180 m · Line 1 in 4 min",
        "4 min",
    )
    draw_card(
        im,
        (72, 1440, 1008, 1670),
        "Terminali i Autobusëve",
        "650 m · Intercity to Prizren",
        "12 min",
    )
    return im


def screenshot_map(icon: Image.Image) -> Image.Image:
    im = add_top_scrim(phone_canvas(MAP_SRC), height=720)
    draw = ImageDraw.Draw(im)
    ic = round_icon(icon.resize((180, 180), Image.Resampling.LANCZOS), 36)
    im.paste(ic, (450, 70), ic)
    title = font(FONT_EXTRABOLD, 64)
    sub = font(FONT_SEMI, 32)
    y = 280
    for line in wrap_text("Every line on the map", title, 920):
        draw_centered_text(draw, line, y, title, WHITE, 1080)
        y += 78
    for line in wrap_text(
        "OpenStreetMap routes and stops for cities in Kosova and Albania.",
        sub,
        900,
    ):
        draw_centered_text(draw, line, y, sub, (226, 232, 240), 1080)
        y += 44
    draw_card(
        im,
        (72, 1540, 1008, 1780),
        "Prishtina · 4 lines",
        "Tap a line to follow the route and see the next departure.",
    )
    return im


def screenshot_cities(icon: Image.Image) -> Image.Image:
    im = add_top_scrim(phone_canvas(STREET_SRC), color=(11, 61, 145))
    draw = ImageDraw.Draw(im)
    ic = round_icon(icon.resize((200, 200), Image.Resampling.LANCZOS), 40)
    im.paste(ic, (440, 80), ic)
    footer = Image.new("RGBA", im.size, (0, 0, 0, 0))
    ImageDraw.Draw(footer).rectangle((0, 1020, 1080, 1920), fill=(247, 248, 250, 255))
    im.alpha_composite(footer)
    title = font(FONT_EXTRABOLD, 62)
    sub = font(FONT_SEMI, 32)
    y = 310
    for line in wrap_text("Kosova and Albania, one app", title, 940):
        draw_centered_text(draw, line, y, title, WHITE, 1080)
        y += 76
    for line in wrap_text(
        "City buses, minibuses, and intercity routes in one place.",
        sub,
        900,
    ):
        draw_centered_text(draw, line, y, sub, (226, 232, 240), 1080)
        y += 44

    cities = [
        ("Prishtinë", "Kosova · 4 lines"),
        ("Tiranë", "Albania · 3 lines"),
        ("Prizren", "Kosova · 2 lines"),
        ("Durrës", "Albania · 1 line"),
    ]
    top = 1080
    for name, meta in cities:
        draw_card(im, (72, top, 1008, top + 180), name, meta)
        top += 196
    return im


def screenshot_search(icon: Image.Image) -> Image.Image:
    # Solid branded screenshot so listing has a clean 4th frame.
    im = Image.new("RGB", (1080, 1920), PRIMARY)
    overlay = Image.new("RGBA", im.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(overlay)
    d.ellipse((-200, 1200, 500, 2000), fill=(30, 91, 184, 180))
    d.ellipse((700, -120, 1300, 480), fill=(232, 93, 4, 70))
    im = Image.alpha_composite(im.convert("RGBA"), overlay)
    draw = ImageDraw.Draw(im)
    ic = round_icon(icon.resize((280, 280), Image.Resampling.LANCZOS), 56)
    im.paste(ic, (400, 180), ic)
    title = font(FONT_EXTRABOLD, 64)
    sub = font(FONT_SEMI, 32)
    y = 500
    for line in wrap_text("Search lines, stops, cities", title, 920):
        draw_centered_text(draw, line, y, title, WHITE, 1080)
        y += 78
    for line in wrap_text(
        "Find a route fast, then open the map or the next departure.",
        sub,
        880,
    ):
        draw_centered_text(draw, line, y, sub, (226, 232, 240), 1080)
        y += 44
    draw_card(im, (72, 980, 1008, 1200), "Line 1 · Qendra – Kalabri", "Bus · every 12 min")
    draw_card(im, (72, 1228, 1008, 1448), "Tirana – Durrës", "Intercity · every 30 min")
    draw_card(im, (72, 1476, 1008, 1696), "Sheshi Skënderbej", "3 lines · next in 8 min")
    return im


def build_tablet(icon: Image.Image) -> None:
    banner = flatten_rgb(BANNER_SRC, fill=PRIMARY)
    banner = crop_inner_frame(banner, 18)
    art = ImageOps_fit(banner, (1920, 1200))
    veil = Image.new("RGBA", art.size, (0, 0, 0, 0))
    vd = ImageDraw.Draw(veil)
    for y in range(0, 420):
        t = 1 - y / 420
        vd.line([(0, y), (1920, y)], fill=(11, 41, 96, int(200 * t)))
    art = Image.alpha_composite(art.convert("RGBA"), veil)
    ic = round_icon(icon.resize((220, 220), Image.Resampling.LANCZOS), 44)
    art.paste(ic, (80, 70), ic)
    draw = ImageDraw.Draw(art)
    draw.text((330, 110), "Soar Albania", font=font(FONT_EXTRABOLD, 64), fill=WHITE)
    draw.text(
        (334, 200),
        "Buses & routes across Kosova and Albania",
        font=font(FONT_SEMI, 32),
        fill=(226, 232, 240),
    )
    save_rgb(art, OUT / "screenshot-tablet-7in-1.png")

    mapped = ImageOps_fit(flatten_rgb(MAP_SRC, fill=PRIMARY), (1920, 1200))
    mapped = add_top_scrim(mapped, height=360)
    draw = ImageDraw.Draw(mapped)
    ic = round_icon(icon.resize((160, 160), Image.Resampling.LANCZOS), 32)
    mapped.paste(ic, (80, 60), ic)
    draw.text((270, 90), "Follow the route", font=font(FONT_EXTRABOLD, 56), fill=WHITE)
    draw.text(
        (274, 170),
        "Map every line and see nearby stops.",
        font=font(FONT_SEMI, 30),
        fill=(226, 232, 240),
    )
    save_rgb(mapped, OUT / "screenshot-tablet-7in-2.png")


def write_readme() -> None:
    text = """# Google Play listing assets

Upload these in Play Console → Grow users → Store presence → Main store listing.

| Play Console field | File | Spec |
|---|---|---|
| App icon | `icon-512.png` | 512×512 PNG, no transparency |
| Feature graphic | `feature-graphic-1024x500.png` | 1024×500 PNG, no transparency |
| Phone screenshots (min 2) | `screenshot-phone-1.png` … `4.png` | 1080×1920 |
| 7-inch tablet (optional) | `screenshot-tablet-7in-1.png`, `2.png` | 1920×1200 |

Suggested screenshot order:

1. Nearby stops / next departure
2. Map
3. Kosova & Albania cities
4. Search

The same 512 icon is also installed as the Android launcher (`android/app/src/main/res/mipmap-*/ic_launcher.png`).

`icon-1024.png` is a spare for later App Store use.

Short description (80 chars max), ready to paste:

```
Buses and routes across Kosova and Albania. Nearby stops and next departures.
```

Full description draft:

```
Soar Albania helps you find buses, minibuses, and intercity lines across Kosova and Albania.

• Nearby stops and the next departure, using your location
• Map of routes and stops
• Browse by city — Prishtinë, Tiranë, Prizren, Durrës, and more
• Search lines, stops, and cities

Schedules in this first release are sample data while live operator feeds are wired in.
```
"""
    (OUT / "README.md").write_text(text)


def main() -> None:
    OUT.mkdir(parents=True, exist_ok=True)
    icon = build_icon()
    build_feature(icon)
    save_rgb(screenshot_nearby(icon), OUT / "screenshot-phone-1.png")
    save_rgb(screenshot_map(icon), OUT / "screenshot-phone-2.png")
    save_rgb(screenshot_cities(icon), OUT / "screenshot-phone-3.png")
    save_rgb(screenshot_search(icon), OUT / "screenshot-phone-4.png")
    build_tablet(icon)
    write_readme()
    print(f"Wrote assets to {OUT}")


if __name__ == "__main__":
    main()

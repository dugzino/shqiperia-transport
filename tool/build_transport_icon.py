#!/usr/bin/env python3
"""Rasterize the bus icon into Play, Android, iOS, and splash assets."""

from __future__ import annotations

import subprocess
from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "store/play/source"
PLAY = ROOT / "store/play"
ANDROID = ROOT / "android/app/src/main/res"
IOS_ICON = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
IOS_LAUNCH = ROOT / "ios/Runner/Assets.xcassets/LaunchImage.imageset"

BLUE = (11, 61, 145)

MIPMAPS = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}
FG_MIPMAPS = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

IOS_ICONS = {
    "Icon-App-20x20@1x.png": 20,
    "Icon-App-20x20@2x.png": 40,
    "Icon-App-20x20@3x.png": 60,
    "Icon-App-29x29@1x.png": 29,
    "Icon-App-29x29@2x.png": 58,
    "Icon-App-29x29@3x.png": 87,
    "Icon-App-40x40@1x.png": 40,
    "Icon-App-40x40@2x.png": 80,
    "Icon-App-40x40@3x.png": 120,
    "Icon-App-60x60@2x.png": 120,
    "Icon-App-60x60@3x.png": 180,
    "Icon-App-76x76@1x.png": 76,
    "Icon-App-76x76@2x.png": 152,
    "Icon-App-83.5x83.5@2x.png": 167,
    "Icon-App-1024x1024@1x.png": 1024,
}


def raster(svg: Path, dest: Path, size: int) -> Image.Image:
    dest.parent.mkdir(parents=True, exist_ok=True)
    subprocess.run(
        ["rsvg-convert", "-w", str(size), "-h", str(size), str(svg), "-o", str(dest)],
        check=True,
    )
    return Image.open(dest).convert("RGBA")


def save_rgb(im: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bg = Image.new("RGB", im.size, BLUE)
    if im.mode == "RGBA":
        bg.paste(im, mask=im.split()[-1])
    else:
        bg.paste(im)
    bg.save(path)


def write_android_xml() -> None:
    (ANDROID / "values" / "ic_launcher_background.xml").write_text(
        """<?xml version="1.0" encoding="utf-8"?>
<resources>
    <color name="ic_launcher_background">#0B3D91</color>
    <color name="splash_background">#0B3D91</color>
</resources>
"""
    )
    anydpi = ANDROID / "mipmap-anydpi-v26"
    anydpi.mkdir(parents=True, exist_ok=True)
    adaptive = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@color/ic_launcher_background" />
    <foreground android:drawable="@mipmap/ic_launcher_foreground" />
</adaptive-icon>
"""
    (anydpi / "ic_launcher.xml").write_text(adaptive)
    (anydpi / "ic_launcher_round.xml").write_text(adaptive)

    splash = """<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_icon" />
    </item>
</layer-list>
"""
    (ANDROID / "drawable" / "launch_background.xml").write_text(splash)
    (ANDROID / "drawable-v21" / "launch_background.xml").write_text(splash)


def main() -> None:
    full = raster(SRC / "icon-bus.svg", SRC / "icon-bus-1024.png", 1024).convert("RGB")
    fg = raster(SRC / "icon-bus-foreground.svg", SRC / "icon-bus-fg-1024.png", 1024)

    PLAY.mkdir(parents=True, exist_ok=True)
    full.save(PLAY / "icon-1024.png")
    full.resize((512, 512), Image.Resampling.LANCZOS).save(PLAY / "icon-512.png")
    full.save(SRC / "icon-master.jpg", quality=95)

    for folder, size in MIPMAPS.items():
        dest = ANDROID / folder
        dest.mkdir(parents=True, exist_ok=True)
        icon = full.resize((size, size), Image.Resampling.LANCZOS)
        icon.save(dest / "ic_launcher.png")
        icon.save(dest / "ic_launcher_round.png")

    for folder, size in FG_MIPMAPS.items():
        dest = ANDROID / folder
        dest.mkdir(parents=True, exist_ok=True)
        fg.resize((size, size), Image.Resampling.LANCZOS).save(
            dest / "ic_launcher_foreground.png"
        )

    # Splash glyph: crop to the bus and keep it large on the boot screen.
    bbox = fg.getbbox()
    bus = fg.crop(bbox)
    pad = 24
    padded = Image.new("RGBA", (bus.width + pad * 2, bus.height + pad * 2), (0, 0, 0, 0))
    padded.paste(bus, (pad, pad), bus)
    width = 320
    height = int(padded.height * (width / padded.width))
    splash = padded.resize((width, height), Image.Resampling.LANCZOS)
    (ANDROID / "drawable").mkdir(parents=True, exist_ok=True)
    splash.save(ANDROID / "drawable" / "splash_icon.png")

    write_android_xml()

    for name, size in IOS_ICONS.items():
        save_rgb(full.resize((size, size), Image.Resampling.LANCZOS), IOS_ICON / name)

    # iOS launch image is the bus glyph on a transparent canvas; storyboard is blue.
    for name, size in {
        "LaunchImage.png": 168,
        "LaunchImage@2x.png": 336,
        "LaunchImage@3x.png": 504,
    }.items():
        fg.resize((size, size), Image.Resampling.LANCZOS).save(IOS_LAUNCH / name)

    print("wrote transport icon, launcher, and splash")


if __name__ == "__main__":
    main()

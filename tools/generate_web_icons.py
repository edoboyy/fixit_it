"""Generate EdoFix web/PWA icons from the light-mode profile photo."""

from __future__ import annotations

import os
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont, ImageOps

ROOT = Path(__file__).resolve().parents[1]
SOURCE = ROOT / "assets" / "images" / "edo_app_logo_source.png"
OUT_DIR = ROOT / "web" / "icons"


def make_icon(photo: Image.Image, size: int, *, maskable: bool = False) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    pad = int(size * (0.08 if maskable else 0.06))
    inner = size - pad * 2
    cx = cy = size // 2
    outer_r = inner // 2

    for y in range(size):
        t = y / max(size - 1, 1)
        r = int(253 + (244 - 253) * t)
        g = int(253 + (244 - 253) * t)
        b = int(253 + (247 - 253) * t)
        draw.line([(0, y), (size, y)], fill=(r, g, b, 255))

    draw.ellipse((cx - outer_r, cy - outer_r, cx + outer_r, cy + outer_r), fill="#FCD116")
    green_r = int(outer_r * 0.92)
    draw.ellipse((cx - green_r, cy - green_r, cx + green_r, cy + green_r), fill="#006B3F")

    photo_r = int(green_r * 0.88)
    photo_size = photo_r * 2
    fitted = ImageOps.fit(photo, (photo_size, photo_size), Image.Resampling.LANCZOS)
    mask = Image.new("L", (photo_size, photo_size), 0)
    ImageDraw.Draw(mask).ellipse((0, 0, photo_size, photo_size), fill=255)
    fitted.putalpha(mask)
    canvas.paste(fitted, (cx - photo_r, cy - photo_r), fitted)

    badge_w = int(size * 0.34)
    badge_h = int(size * 0.11)
    bx1 = cx - badge_w // 2
    by1 = cy + int(photo_r * 0.55)
    bx2 = bx1 + badge_w
    by2 = by1 + badge_h
    draw.rounded_rectangle((bx1, by1, bx2, by2), radius=badge_h // 2, fill="#006B3F")
    draw.rounded_rectangle(
        (bx1 + 2, by1 + 2, bx2 - 2, by2 - 2),
        radius=max(badge_h // 2 - 2, 1),
        outline="#FCD116",
        width=max(2, size // 128),
    )

    try:
        font = ImageFont.truetype("arialbd.ttf", max(14, size // 14))
    except OSError:
        font = ImageFont.load_default()
    text = "EDO"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw / 2, by1 + (badge_h - th) / 2 - 1), text, fill="white", font=font)

    return canvas


def main() -> None:
    if not SOURCE.exists():
        raise FileNotFoundError(f"Missing source image: {SOURCE}")

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    photo = Image.open(SOURCE).convert("RGBA")
    photo = ImageOps.exif_transpose(photo)

    for name, size, maskable in (
        ("Icon-192.png", 192, False),
        ("Icon-512.png", 512, False),
        ("Icon-maskable-192.png", 192, True),
        ("Icon-maskable-512.png", 512, True),
    ):
        make_icon(photo, size, maskable=maskable).save(OUT_DIR / name, "PNG")

    make_icon(photo, 64).save(ROOT / "web" / "favicon.png", "PNG")
    print(f"Generated icons in {OUT_DIR}")


if __name__ == "__main__":
    main()

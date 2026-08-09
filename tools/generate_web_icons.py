"""Generate Fixit GH web/PWA icons."""

from __future__ import annotations

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT / "web" / "icons"

GREEN = "#006B3F"
GOLD = "#FCD116"
WHITE = "#FFFFFF"
DARK = "#0B3D2E"


def _draw_tool_icon(draw: ImageDraw.ImageDraw, cx: int, cy: int, size: int) -> None:
    s = size
    # Wrench handle
    draw.rounded_rectangle(
        (cx - int(s * 0.34), cy - int(s * 0.08), cx + int(s * 0.08), cy + int(s * 0.08)),
        radius=int(s * 0.08),
        fill=GREEN,
    )
    # Wrench head
    draw.ellipse(
        (cx + int(s * 0.02), cy - int(s * 0.22), cx + int(s * 0.34), cy + int(s * 0.22)),
        fill=GREEN,
    )
    draw.ellipse(
        (cx + int(s * 0.10), cy - int(s * 0.12), cx + int(s * 0.24), cy + int(s * 0.12)),
        fill=GOLD,
    )
    # Hammer head
    draw.rounded_rectangle(
        (cx - int(s * 0.30), cy - int(s * 0.30), cx - int(s * 0.04), cy - int(s * 0.14)),
        radius=int(s * 0.04),
        fill=GREEN,
    )
    draw.rounded_rectangle(
        (cx - int(s * 0.10), cy - int(s * 0.12), cx + int(s * 0.10), cy + int(s * 0.34)),
        radius=int(s * 0.05),
        fill=GREEN,
    )


def make_icon(size: int, *, maskable: bool = False) -> Image.Image:
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(canvas)

    pad = int(size * (0.08 if maskable else 0.05))
    box = size - pad * 2

    # App tile background
    draw.rounded_rectangle(
        (pad, pad, pad + box, pad + box),
        radius=int(size * 0.22),
        fill=GREEN,
    )

    cx = cy = size // 2
    gold_r = int(box * 0.30)
    draw.ellipse(
        (cx - gold_r, cy - int(gold_r * 1.05), cx + gold_r, cy + int(gold_r * 0.75)),
        fill=GOLD,
    )

    _draw_tool_icon(draw, cx, cy - int(size * 0.04), int(size * 0.34))

    badge_w = int(size * 0.56)
    badge_h = int(size * 0.12)
    bx1 = cx - badge_w // 2
    by1 = pad + box - badge_h - int(size * 0.05)
    bx2 = bx1 + badge_w
    by2 = by1 + badge_h
    draw.rounded_rectangle((bx1, by1, bx2, by2), radius=badge_h // 2, fill=DARK)
    draw.rounded_rectangle(
        (bx1 + 2, by1 + 2, bx2 - 2, by2 - 2),
        radius=max(badge_h // 2 - 2, 1),
        outline=GOLD,
        width=max(2, size // 128),
    )

    try:
        font = ImageFont.truetype("arialbd.ttf", max(11, size // 18))
    except OSError:
        font = ImageFont.load_default()
    text = "FIXIT GH"
    bbox = draw.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    draw.text((cx - tw / 2, by1 + (badge_h - th) / 2 - 1), text, fill=WHITE, font=font)

    return canvas


def main() -> None:
    OUT_DIR.mkdir(parents=True, exist_ok=True)

    for name, size, maskable in (
        ("Icon-192.png", 192, False),
        ("Icon-512.png", 512, False),
        ("Icon-maskable-192.png", 192, True),
        ("Icon-maskable-512.png", 512, True),
    ):
        make_icon(size, maskable=maskable).save(OUT_DIR / name, "PNG")

    make_icon(64).save(ROOT / "web" / "favicon.png", "PNG")
    make_icon(512).save(ROOT / "assets" / "images" / "fixit_gh_app_icon.png", "PNG")
    print(f"Generated Fixit GH icons in {OUT_DIR}")


if __name__ == "__main__":
    main()

"""Generate in-app logos, app icons and the favicon from the brand/ originals.

Run from the repo root: python3 tools/make_brand_assets.py
"""
import json
import re
from pathlib import Path

from PIL import Image

BRAND = Path("brand")


def transparent(im):
    """Near-white background -> transparent, keeping anti-aliased edges."""
    im = im.convert("RGBA")
    px = im.load()
    for y in range(im.height):
        for x in range(im.width):
            r, g, b, a = px[x, y]
            alpha = max(0, min(255, (248 - min(r, g, b)) * 255 // 48))
            px[x, y] = (r, g, b, min(a, alpha))
    return im


def trim(im, pad=0):
    box = im.getchannel("A").point(lambda v: 255 if v > 24 else 0).getbbox()
    im = im.crop(box)
    if pad:
        out = Image.new("RGBA", (im.width + 2 * pad, im.height + 2 * pad), (0, 0, 0, 0))
        out.paste(im, (pad, pad))
        im = out
    return im


def split_mark(logo):
    """Split the full logo at the widest empty column gap: (mark, wordmark)."""
    alpha = logo.getchannel("A")
    cols = [any(alpha.getpixel((x, y)) > 24 for y in range(0, logo.height, 2)) for x in range(logo.width)]
    best, start = (0, 0), None
    for x, filled in enumerate(cols + [True]):
        if not filled and start is None:
            start = x
        elif filled and start is not None:
            if x - start > best[1] - best[0]:
                best = (start, x)
            start = None
    cut = (best[0] + best[1]) // 2
    return trim(logo.crop((0, 0, cut, logo.height))), trim(logo.crop((cut, 0, logo.width, logo.height)))


def square(im, size, scale, bg=(255, 255, 255, 255)):
    """Center im in a size x size canvas, fitting it into scale * size."""
    canvas = Image.new("RGBA", (size, size), bg)
    fit = im.copy()
    fit.thumbnail((int(size * scale), int(size * scale)), Image.LANCZOS)
    canvas.alpha_composite(fit, ((size - fit.width) // 2, (size - fit.height) // 2))
    return canvas


logo = trim(transparent(Image.open(BRAND / "logo-full.jpg")))
mark, wordmark = split_mark(logo)
logo.save("assets/brand/logo.png", optimize=True)
mark.save("assets/brand/mark.png", optimize=True)
wordmark.save("assets/brand/wordmark.png", optimize=True)

# An app icon uploaded in the admin panel (fetched by apply_remote_icon.py) wins.
override = BRAND / "app-icon-override.png"
icon_src = trim(transparent(Image.open(override))) if override.exists() else mark
icon = square(icon_src, 1024, 0.84)

# Android launcher icons.
for folder, size in {"mdpi": 48, "hdpi": 72, "xhdpi": 96, "xxhdpi": 144, "xxxhdpi": 192}.items():
    icon.resize((size, size), Image.LANCZOS).save(f"android/app/src/main/res/mipmap-{folder}/ic_launcher.png")

# iOS icons (no alpha allowed).
ios = Path("ios/Runner/Assets.xcassets/AppIcon.appiconset")
for img in json.load(open(ios / "Contents.json"))["images"]:
    w = float(img["size"].split("x")[0]) * int(img["scale"].rstrip("x"))
    icon.convert("RGB").resize((round(w), round(w)), Image.LANCZOS).save(ios / img["filename"])

# Web / PWA icons; maskable ones keep the mark inside the safe zone.
for size in (192, 512):
    icon.resize((size, size), Image.LANCZOS).save(f"web/icons/Icon-{size}.png")
    square(mark, size, 0.6).save(f"web/icons/Icon-maskable-{size}.png")

# Favicon from the round W-check icon.
fav = trim(transparent(Image.open(BRAND / "icon-round.png")))
square(fav, 64, 1.0, bg=(0, 0, 0, 0)).save("web/favicon.png")
print("logo", logo.size, "mark", mark.size)

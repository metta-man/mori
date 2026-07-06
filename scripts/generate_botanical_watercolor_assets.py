#!/usr/bin/env python3
"""Generate Mori botanical watercolor bitmap assets.

The assets intentionally avoid logo-like seedling badges, circular marks,
wordmarks, or centered symbols. Cards get quiet paper grain; screens get
edge/corner botanical washes with generous empty paper.
"""

from __future__ import annotations

import argparse
import filecmp
import json
import math
import random
import shutil
import tempfile
from dataclasses import dataclass
from pathlib import Path

from PIL import Image, ImageChops, ImageDraw, ImageFilter, ImageOps


ROOT = Path(__file__).resolve().parents[1]
BACKGROUND_ROOT = ROOT / "DesignSystem" / "MoriBackgrounds.xcassets"
GENERATED_ROOT = ROOT / "Shared" / "MoriGeneratedArt.xcassets"
WEB_BOTANICAL_ROOT = ROOT / "www" / "src" / "assets" / "botanical"
MASTER_ROOT = ROOT / "DesignSystem" / "BotanicalWatercolorMasters"

PAPER = (250, 247, 239)
PAPER_WARM = (255, 250, 241)
INK = (80, 96, 71)
MOSS = (104, 126, 94)
SAGE = (143, 158, 133)
MIST = (130, 146, 154)
ROOT_BROWN = (145, 105, 83)
CLAY = (185, 133, 109)
SEED_GOLD = (216, 184, 111)


@dataclass(frozen=True)
class BackdropSpec:
    name: str
    size: tuple[int, int]
    seed: int
    anchor: str
    tint: tuple[int, int, int]
    motif: str
    wash_strength: float = 1.0


BACKDROPS: tuple[BackdropSpec, ...] = (
    BackdropSpec("BotanicalBackdropOnboarding", (1254, 1254), 101, "top_right", SAGE, "grass", 0.82),
    BackdropSpec("BotanicalBackdropAppLimit", (1254, 1254), 102, "bottom_left", MOSS, "stem", 0.86),
    BackdropSpec("BotanicalBackdropToday", (1254, 1254), 103, "top_right", SAGE, "canopy", 0.78),
    BackdropSpec("BotanicalBackdropPractice", (1254, 1254), 104, "bottom_right", MIST, "fern", 0.72),
    BackdropSpec("BotanicalBackdropJournal", (1254, 1254), 105, "bottom_left", ROOT_BROWN, "pressed", 0.72),
    BackdropSpec("BotanicalBackdropSettings", (1254, 1254), 106, "top_left", SAGE, "stem", 0.64),
    BackdropSpec("BotanicalBackdropHomeHero", (1254, 1254), 107, "right", MOSS, "canopy", 0.90),
    BackdropSpec("BotanicalBackdropFocus", (1254, 1254), 108, "bottom_right", MOSS, "fern", 0.78),
    BackdropSpec("BotanicalBackdropBell", (1254, 1254), 109, "bottom_left", SEED_GOLD, "grass", 0.70),
    BackdropSpec("BotanicalBackdropBellTile", (1254, 1254), 110, "top_right", SEED_GOLD, "pressed", 0.58),
    BackdropSpec("BotanicalBackdropBreathe", (1254, 1254), 111, "bottom_right", MIST, "canopy", 0.74),
    BackdropSpec("BotanicalBackdropCoolTile", (1254, 1254), 112, "top_left", MIST, "fern", 0.58),
    BackdropSpec("BotanicalBackdropWarmTile", (1254, 1254), 113, "bottom_left", CLAY, "pressed", 0.62),
    BackdropSpec("BotanicalBackdropRoots", (1254, 1254), 114, "bottom_left", ROOT_BROWN, "roots", 0.76),
    BackdropSpec("BotanicalBackdropRootsTile", (1254, 1254), 115, "bottom_right", ROOT_BROWN, "roots", 0.58),
    BackdropSpec("BotanicalBackdropSoftCanopy", (853, 1844), 116, "bottom", SAGE, "canopy", 0.68),
)

WEB_BACKGROUND_MAP = {
    "onboarding-paper.png": "BotanicalBackdropOnboarding",
    "app-limit-paper.png": "BotanicalBackdropAppLimit",
    "today-paper.png": "BotanicalBackdropToday",
    "practice-paper.png": "BotanicalBackdropPractice",
}

BACKGROUND_MASTER_MAP = {
    "BotanicalBackdropOnboarding": ("BotanicalBackdropToday", "none"),
    "BotanicalBackdropAppLimit": ("BotanicalBackdropAppLimit", "none"),
    "BotanicalBackdropToday": ("BotanicalBackdropToday", "none"),
    "BotanicalBackdropPractice": ("BotanicalBackdropPractice", "none"),
    "BotanicalBackdropJournal": ("BotanicalBackdropJournal", "none"),
    "BotanicalBackdropSettings": ("BotanicalBackdropSettings", "none"),
    "BotanicalBackdropHomeHero": ("BotanicalBackdropToday", "mirror"),
    "BotanicalBackdropFocus": ("BotanicalBackdropPractice", "mirror"),
    "BotanicalBackdropBell": ("BotanicalBackdropAppLimit", "none"),
    "BotanicalBackdropBellTile": ("BotanicalBackdropAppLimit", "mirror"),
    "BotanicalBackdropBreathe": ("BotanicalBackdropPractice", "none"),
    "BotanicalBackdropCoolTile": ("BotanicalBackdropPractice", "mirror"),
    "BotanicalBackdropWarmTile": ("BotanicalBackdropJournal", "none"),
    "BotanicalBackdropRoots": ("BotanicalBackdropJournal", "none"),
    "BotanicalBackdropRootsTile": ("BotanicalBackdropJournal", "mirror"),
    "BotanicalBackdropSoftCanopy": ("BotanicalBackdropToday", "none"),
}

ORNAMENT_MASTER_MAP = {
    "BotanicalOrnamentStoneSprout": ("BotanicalBackdropSettings", "none"),
    "BotanicalOrnamentBellChime": ("BotanicalBackdropAppLimit", "none"),
    "BotanicalOrnamentRootsRings": ("BotanicalBackdropJournal", "mirror"),
}

MASTER_CENTERING = {
    "BotanicalBackdropToday": (0.08, 0.52),
    "BotanicalBackdropAppLimit": (0.88, 0.54),
    "BotanicalBackdropPractice": (0.50, 0.54),
    "BotanicalBackdropJournal": (0.86, 0.54),
    "BotanicalBackdropSettings": (0.22, 0.52),
}

RESAMPLE = Image.Resampling.LANCZOS if hasattr(Image, "Resampling") else Image.LANCZOS


def mix(a: tuple[int, int, int], b: tuple[int, int, int], t: float) -> tuple[int, int, int]:
    return tuple(int(a[i] * (1 - t) + b[i] * t) for i in range(3))


def save_png(image: Image.Image, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    image.save(path, optimize=True)


def save_imageset_contents(path: Path, images: list[dict[str, str]]) -> None:
    path.mkdir(parents=True, exist_ok=True)
    payload = {
        "images": images,
        "info": {
            "author": "xcode",
            "version": 1,
        },
    }
    (path / "Contents.json").write_text(
        json.dumps(payload, indent=2) + "\n",
        encoding="utf-8",
    )


def save_single_scale_contents(imageset_path: Path, filename: str) -> None:
    save_imageset_contents(
        imageset_path,
        [
            {"filename": filename, "idiom": "universal", "scale": "1x"},
            {"idiom": "universal", "scale": "2x"},
            {"idiom": "universal", "scale": "3x"},
        ],
    )


def load_watercolor_master(master_name: str) -> Image.Image:
    path = MASTER_ROOT / f"{master_name}.png"
    if not path.exists():
        raise FileNotFoundError(
            f"Missing watercolor master {path.relative_to(ROOT)}. "
            "Restore the raster PNG masters before regenerating assets."
        )
    return Image.open(path).convert("RGBA")


def transform_master(image: Image.Image, transform: str) -> Image.Image:
    if transform == "none":
        return image
    if transform == "mirror":
        return ImageOps.mirror(image)
    raise ValueError(f"Unsupported watercolor master transform: {transform}")


def watercolor_master_canvas(
    master_name: str,
    size: tuple[int, int],
    seed: int,
    transform: str = "none",
) -> Image.Image:
    source = transform_master(load_watercolor_master(master_name), transform)
    centering = MASTER_CENTERING[master_name]
    if transform == "mirror":
        centering = (1 - centering[0], centering[1])
    return ImageOps.fit(source, size, method=RESAMPLE, centering=centering)


def save_generated_scale_contents(imageset_path: Path, asset_name: str) -> None:
    save_imageset_contents(
        imageset_path,
        [
            {"filename": f"{asset_name}@1x.png", "idiom": "universal", "scale": "1x"},
            {"filename": f"{asset_name}@2x.png", "idiom": "universal", "scale": "2x"},
            {"filename": f"{asset_name}@3x.png", "idiom": "universal", "scale": "3x"},
        ],
    )


def add_paper_texture(image: Image.Image, rng: random.Random, strength: float = 1.0) -> Image.Image:
    width, height = image.size
    pixels = image.load()
    for y in range(height):
        row_shift = rng.randint(-2, 2)
        for x in range(width):
            n = rng.randint(-7, 7)
            if (x + y + row_shift) % 19 == 0:
                n -= rng.randint(2, 8)
            r, g, b, a = pixels[x, y]
            d = int(n * strength)
            pixels[x, y] = (
                max(0, min(255, r + d)),
                max(0, min(255, g + d)),
                max(0, min(255, b + d)),
                a,
            )

    fiber = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(fiber, "RGBA")
    fiber_count = max(240, int(width * height / 2600))
    for _ in range(fiber_count):
        x = rng.randint(-20, width + 20)
        y = rng.randint(-20, height + 20)
        length = rng.randint(18, 92)
        angle = rng.uniform(-0.25, 0.25) + rng.choice([0, math.pi])
        color = rng.choice([(122, 116, 100, 14), (255, 255, 255, 18), (94, 118, 93, 8)])
        draw.line(
            [
                (x, y),
                (x + math.cos(angle) * length, y + math.sin(angle) * length),
            ],
            fill=color,
            width=rng.choice([1, 1, 2]),
        )
    fiber = fiber.filter(ImageFilter.GaussianBlur(radius=0.45))
    return Image.alpha_composite(image, fiber)


def paper_canvas(size: tuple[int, int], seed: int, warm: float = 0.38) -> Image.Image:
    rng = random.Random(seed)
    base = Image.new("RGBA", size, (*mix(PAPER, PAPER_WARM, warm), 255))
    return add_paper_texture(base, rng, strength=0.82)


def anchor_point(size: tuple[int, int], anchor: str) -> tuple[float, float]:
    width, height = size
    points = {
        "bottom_right": (width * 0.84, height * 0.83),
        "bottom_left": (width * 0.16, height * 0.84),
        "top_right": (width * 0.82, height * 0.20),
        "top_left": (width * 0.18, height * 0.18),
        "right": (width * 0.88, height * 0.54),
        "bottom": (width * 0.52, height * 0.76),
    }
    return points[anchor]


def add_wash(image: Image.Image, rng: random.Random, spec: BackdropSpec) -> Image.Image:
    width, height = image.size
    ax, ay = anchor_point(image.size, spec.anchor)
    layer = Image.new("RGBA", image.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(layer, "RGBA")

    for _ in range(62):
        radius_x = rng.uniform(width * 0.12, width * 0.34) * spec.wash_strength
        radius_y = rng.uniform(height * 0.06, height * 0.20) * spec.wash_strength
        dx = rng.uniform(-width * 0.18, width * 0.18)
        dy = rng.uniform(-height * 0.14, height * 0.14)
        color = mix(spec.tint, PAPER, rng.uniform(0.38, 0.72))
        alpha = int(rng.uniform(24, 70) * spec.wash_strength)
        draw.ellipse(
            (ax + dx - radius_x, ay + dy - radius_y, ax + dx + radius_x, ay + dy + radius_y),
            fill=(*color, alpha),
        )

    for _ in range(18):
        x = rng.uniform(width * -0.05, width * 1.05)
        y = rng.uniform(height * 0.05, height * 0.95)
        s = rng.uniform(2.0, 8.0)
        color = mix(spec.tint, PAPER, rng.uniform(0.22, 0.55))
        draw.ellipse((x - s, y - s, x + s, y + s), outline=(*color, rng.randint(18, 46)), width=1)

    layer = layer.filter(ImageFilter.GaussianBlur(radius=max(width, height) * 0.018))
    return Image.alpha_composite(image, layer)


def bezier(p0, p1, p2, p3, steps: int = 34) -> list[tuple[float, float]]:
    points = []
    for i in range(steps + 1):
        t = i / steps
        x = (
            (1 - t) ** 3 * p0[0]
            + 3 * (1 - t) ** 2 * t * p1[0]
            + 3 * (1 - t) * t**2 * p2[0]
            + t**3 * p3[0]
        )
        y = (
            (1 - t) ** 3 * p0[1]
            + 3 * (1 - t) ** 2 * t * p1[1]
            + 3 * (1 - t) * t**2 * p2[1]
            + t**3 * p3[1]
        )
        points.append((x, y))
    return points


def leaf_polygon(cx: float, cy: float, length: float, width: float, angle: float) -> list[tuple[float, float]]:
    points: list[tuple[float, float]] = []
    for i in range(15):
        t = i / 14
        taper = math.sin(t * math.pi)
        x = (t - 0.5) * length
        y = -width * taper
        points.append(rotate_point(cx, cy, x, y, angle))
    for i in range(14, -1, -1):
        t = i / 14
        taper = math.sin(t * math.pi)
        x = (t - 0.5) * length
        y = width * taper
        points.append(rotate_point(cx, cy, x, y, angle))
    return points


def rotate_point(cx: float, cy: float, x: float, y: float, angle: float) -> tuple[float, float]:
    return (cx + x * math.cos(angle) - y * math.sin(angle), cy + x * math.sin(angle) + y * math.cos(angle))


def draw_leaf(
    draw: ImageDraw.ImageDraw,
    cx: float,
    cy: float,
    length: float,
    width: float,
    angle: float,
    color: tuple[int, int, int],
    alpha: int,
) -> None:
    for scale, extra_alpha in ((1.0, alpha), (0.82, int(alpha * 0.46)), (0.58, int(alpha * 0.32))):
        jitter = (1.0 - scale) * length * 0.08
        polygon = leaf_polygon(cx + jitter, cy - jitter, length * scale, width * scale, angle)
        draw.polygon(polygon, fill=(*color, extra_alpha))

    start = rotate_point(cx, cy, -length * 0.42, 0, angle)
    end = rotate_point(cx, cy, length * 0.43, 0, angle)
    draw.line([start, end], fill=(*mix(color, INK, 0.36), int(alpha * 0.52)), width=max(1, int(width * 0.08)))


def draw_branch(layer: Image.Image, rng: random.Random, spec: BackdropSpec, count: int) -> None:
    width, height = layer.size
    draw = ImageDraw.Draw(layer, "RGBA")
    ax, ay = anchor_point(layer.size, spec.anchor)
    base_angle = {
        "bottom_right": -2.18,
        "bottom_left": -0.92,
        "top_right": 2.35,
        "top_left": 0.72,
        "right": math.pi,
        "bottom": -math.pi / 2,
    }[spec.anchor]

    for branch_index in range(count):
        length = rng.uniform(min(width, height) * 0.22, min(width, height) * 0.48)
        angle = base_angle + rng.uniform(-0.52, 0.52)
        start = (
            ax + rng.uniform(-width * 0.08, width * 0.08),
            ay + rng.uniform(-height * 0.06, height * 0.06),
        )
        end = (start[0] + math.cos(angle) * length, start[1] + math.sin(angle) * length)
        control1 = (start[0] + math.cos(angle - 0.4) * length * 0.36, start[1] + math.sin(angle - 0.4) * length * 0.36)
        control2 = (start[0] + math.cos(angle + 0.26) * length * 0.72, start[1] + math.sin(angle + 0.26) * length * 0.72)
        points = bezier(start, control1, control2, end, steps=42)
        stem_color = mix(spec.tint, INK, 0.38)
        draw.line(points, fill=(*stem_color, rng.randint(58, 96)), width=max(2, int(width * 0.004)))

        leaf_count = rng.randint(4, 8)
        for i in range(leaf_count):
            idx = int((i + 1) / (leaf_count + 1) * (len(points) - 1))
            px, py = points[idx]
            side = -1 if (i + branch_index) % 2 else 1
            leaf_angle = angle + side * rng.uniform(0.72, 1.18)
            leaf_len = rng.uniform(min(width, height) * 0.045, min(width, height) * 0.080)
            leaf_width = leaf_len * rng.uniform(0.22, 0.34)
            color = mix(spec.tint, PAPER, rng.uniform(0.02, 0.22))
            draw_leaf(draw, px, py, leaf_len, leaf_width, leaf_angle, color, rng.randint(64, 114))


def draw_roots(layer: Image.Image, rng: random.Random, spec: BackdropSpec) -> None:
    width, height = layer.size
    draw = ImageDraw.Draw(layer, "RGBA")
    ax, ay = anchor_point(layer.size, spec.anchor)
    root_color = mix(ROOT_BROWN, INK, 0.20)
    for _ in range(18):
        angle = rng.uniform(-2.95, -0.24) if spec.anchor.endswith("right") else rng.uniform(-2.9, -0.18)
        length = rng.uniform(width * 0.10, width * 0.30)
        points = [(ax, ay)]
        for step in range(1, 6):
            t = step / 5
            points.append(
                (
                    ax + math.cos(angle + rng.uniform(-0.32, 0.32)) * length * t,
                    ay + math.sin(angle + rng.uniform(-0.22, 0.22)) * length * t + height * 0.07 * t,
                )
            )
        draw.line(points, fill=(*root_color, rng.randint(28, 58)), width=rng.choice([1, 1, 2]))


def add_botanical(layer: Image.Image, rng: random.Random, spec: BackdropSpec) -> None:
    if spec.motif == "canopy":
        draw_branch(layer, rng, spec, count=3)
    elif spec.motif == "fern":
        draw_branch(layer, rng, spec, count=2)
    elif spec.motif == "stem":
        draw_branch(layer, rng, spec, count=2)
    elif spec.motif == "grass":
        draw_branch(layer, rng, spec, count=2)
    elif spec.motif == "pressed":
        draw_branch(layer, rng, spec, count=1)
    elif spec.motif == "roots":
        draw_branch(layer, rng, spec, count=1)
        draw_roots(layer, rng, spec)


def generate_backdrop(spec: BackdropSpec) -> Image.Image:
    rng = random.Random(spec.seed)
    image = paper_canvas(spec.size, spec.seed, warm=0.36)
    image = add_wash(image, rng, spec)
    botanical = Image.new("RGBA", spec.size, (0, 0, 0, 0))
    add_botanical(botanical, rng, spec)
    botanical = botanical.filter(ImageFilter.GaussianBlur(radius=0.42))

    fade = Image.new("L", spec.size, 0)
    fade_draw = ImageDraw.Draw(fade)
    ax, ay = anchor_point(spec.size, spec.anchor)
    radius = max(spec.size) * 0.62
    fade_draw.ellipse((ax - radius, ay - radius, ax + radius, ay + radius), fill=235)
    fade = fade.filter(ImageFilter.GaussianBlur(radius=max(spec.size) * 0.18))
    botanical.putalpha(ImageChops.multiply(botanical.getchannel("A"), fade))
    return Image.alpha_composite(image, botanical)


def generate_ornament(size: tuple[int, int], seed: int, tint: tuple[int, int, int], motif: str) -> Image.Image:
    spec = BackdropSpec("ornament", size, seed, "right", tint, motif, 0.60)
    rng = random.Random(seed)
    image = Image.new("RGBA", size, (245, 241, 232, 255))
    card = paper_canvas((520, 420), seed + 1, warm=0.45)
    card_spec = BackdropSpec("ornament-card", card.size, seed + 2, "right", tint, motif, 0.52)
    card = add_wash(card, rng, card_spec)
    botanical = Image.new("RGBA", card.size, (0, 0, 0, 0))
    add_botanical(botanical, rng, card_spec)
    botanical = botanical.filter(ImageFilter.GaussianBlur(radius=0.36))
    card = Image.alpha_composite(card, botanical)

    mask = Image.new("L", card.size, 0)
    draw = ImageDraw.Draw(mask)
    draw.rounded_rectangle((0, 0, card.size[0], card.size[1]), radius=28, fill=255)
    draw.polygon([(0, 0), (56, 0), (0, 56)], fill=0)
    draw.polygon([(card.size[0], card.size[1]), (card.size[0] - 56, card.size[1]), (card.size[0], card.size[1] - 56)], fill=0)
    x = (size[0] - card.size[0]) // 2
    y = (size[1] - card.size[1]) // 2
    image.paste(card, (x, y), mask)
    return image


def generate_generated_art(name: str, size: tuple[int, int], seed: int, role: str) -> Image.Image:
    image = paper_canvas(size, seed, warm=0.44)
    rng = random.Random(seed)

    if role == "card":
        return image

    if role.startswith("card-"):
        card_variants = {
            "card-sage": ("top_right", SAGE, "pressed", 0.18),
            "card-warm": ("bottom_left", CLAY, "grass", 0.16),
            "card-cool": ("bottom_right", MIST, "fern", 0.16),
        }
        anchor, tint, motif, strength = card_variants[role]
        spec = BackdropSpec(name, size, seed + 77, anchor, tint, motif, strength)
        image = add_wash(image, rng, spec)

        botanical = Image.new("RGBA", size, (0, 0, 0, 0))
        add_botanical(botanical, rng, spec)
        botanical = botanical.filter(ImageFilter.GaussianBlur(radius=0.34))

        fade = Image.new("L", size, 0)
        fade_draw = ImageDraw.Draw(fade)
        ax, ay = anchor_point(size, anchor)
        radius = max(size) * 0.46
        fade_draw.ellipse((ax - radius, ay - radius, ax + radius, ay + radius), fill=180)
        fade = fade.filter(ImageFilter.GaussianBlur(radius=max(size) * 0.16))
        botanical_alpha = ImageChops.multiply(botanical.getchannel("A"), fade).point(lambda value: int(value * 0.26))
        botanical.putalpha(botanical_alpha)
        return Image.alpha_composite(image, botanical)

    if role == "screen":
        spec = BackdropSpec(name, size, seed + 77, "top_right", SAGE, "pressed", 0.30)
        image = add_wash(image, rng, spec)
        botanical = Image.new("RGBA", size, (0, 0, 0, 0))
        add_botanical(botanical, rng, spec)
        botanical = botanical.filter(ImageFilter.GaussianBlur(radius=0.38))
        botanical_alpha = botanical.getchannel("A").point(lambda value: int(value * 0.34))
        botanical.putalpha(botanical_alpha)
        return Image.alpha_composite(image, botanical)

    if role == "button":
        spec = BackdropSpec(name, size, seed + 77, "bottom_right", SAGE, "pressed", 0.26)
        image = add_wash(image, rng, spec)

    return image


def write_assets(root: Path) -> None:
    background_root = root / "DesignSystem" / "MoriBackgrounds.xcassets"
    generated_root = root / "Shared" / "MoriGeneratedArt.xcassets"
    web_root = root / "www" / "src" / "assets" / "botanical"
    web_root.mkdir(parents=True, exist_ok=True)
    shutil.rmtree(generated_root / "moriBotanicalCardWash.imageset", ignore_errors=True)

    for spec in BACKDROPS:
        master_name, transform = BACKGROUND_MASTER_MAP[spec.name]
        imageset_path = background_root / f"{spec.name}.imageset"
        save_png(
            watercolor_master_canvas(master_name, spec.size, spec.seed, transform),
            imageset_path / f"{spec.name}.png",
        )
        save_single_scale_contents(imageset_path, f"{spec.name}.png")

    ornaments = (
        ("BotanicalOrnamentStoneSprout", 201),
        ("BotanicalOrnamentBellChime", 202),
        ("BotanicalOrnamentRootsRings", 203),
    )
    for name, seed in ornaments:
        master_name, transform = ORNAMENT_MASTER_MAP[name]
        imageset_path = background_root / f"{name}.imageset"
        save_png(
            watercolor_master_canvas(master_name, (720, 720), seed, transform),
            imageset_path / f"{name}.png",
        )
        save_single_scale_contents(imageset_path, f"{name}.png")

    generated_specs = (
        ("moriCardPaperWash", (400, 240), 301, "card"),
        ("moriCardPaperWash", (800, 480), 302, "card"),
        ("moriCardPaperWash", (1200, 720), 303, "card"),
        ("moriCardSageWash", (400, 240), 304, "card-sage"),
        ("moriCardSageWash", (800, 480), 305, "card-sage"),
        ("moriCardSageWash", (1200, 720), 306, "card-sage"),
        ("moriCardWarmWash", (400, 240), 314, "card-warm"),
        ("moriCardWarmWash", (800, 480), 315, "card-warm"),
        ("moriCardWarmWash", (1200, 720), 316, "card-warm"),
        ("moriCardCoolWash", (400, 240), 317, "card-cool"),
        ("moriCardCoolWash", (800, 480), 318, "card-cool"),
        ("moriCardCoolWash", (1200, 720), 319, "card-cool"),
        ("moriBotanicalScreenWash", (400, 240), 310, "screen"),
        ("moriBotanicalScreenWash", (800, 480), 311, "screen"),
        ("moriBotanicalScreenWash", (1200, 720), 312, "screen"),
        ("moriWidgetPaperWash", (342, 342), 330, "card"),
        ("moriWidgetPaperWash", (684, 684), 331, "card"),
        ("moriWidgetPaperWash", (1024, 1024), 332, "card"),
        ("moriWidgetBotanicalWash", (342, 342), 333, "screen"),
        ("moriWidgetBotanicalWash", (684, 684), 334, "screen"),
        ("moriWidgetBotanicalWash", (1024, 1024), 335, "screen"),
        ("moriButtonWash", (400, 120), 307, "button"),
        ("moriButtonWash", (800, 240), 308, "button"),
        ("moriButtonWash", (1200, 360), 309, "button"),
    )
    scales = ("@1x", "@2x", "@3x")
    for index, (asset_name, size, seed, role) in enumerate(generated_specs):
        scale = scales[index % len(scales)]
        save_png(
            generate_generated_art(asset_name, size, seed, role),
            generated_root / f"{asset_name}.imageset" / f"{asset_name}{scale}.png",
        )

    for asset_name in {asset_name for asset_name, _size, _seed, _role in generated_specs}:
        save_generated_scale_contents(generated_root / f"{asset_name}.imageset", asset_name)

    for web_name, native_name in WEB_BACKGROUND_MAP.items():
        shutil.copyfile(
            background_root / f"{native_name}.imageset" / f"{native_name}.png",
            web_root / web_name,
        )
    shutil.copyfile(
        generated_root / "moriCardPaperWash.imageset" / "moriCardPaperWash@3x.png",
        web_root / "card-paper.png",
    )


def check_assets() -> int:
    with tempfile.TemporaryDirectory(prefix="mori-botanical-assets-") as tmp:
        expected_root = Path(tmp)
        write_assets(expected_root)
        failures: list[str] = []
        expected_files = list(expected_root.rglob("*.png")) + list(expected_root.rglob("Contents.json"))
        for expected in expected_files:
            actual = ROOT / expected.relative_to(expected_root)
            if not actual.exists():
                failures.append(f"missing {actual.relative_to(ROOT)}")
            elif not filecmp.cmp(expected, actual, shallow=False):
                failures.append(f"outdated {actual.relative_to(ROOT)}")

        deprecated_paths = (
            GENERATED_ROOT / "moriBotanicalCardWash.imageset",
        )
        for deprecated in deprecated_paths:
            if deprecated.exists():
                failures.append(f"deprecated card-level botanical asset still present {deprecated.relative_to(ROOT)}")

    if failures:
        print("Botanical watercolor assets are not generated from the active raster-watercolor master recipe:")
        for item in failures:
            print(f"::error::{item}")
        print("Run: scripts/generate_botanical_watercolor_assets.py")
        return 1
    print("OK: botanical watercolor assets match the raster watercolor master recipe.")
    return 0


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--check", action="store_true", help="verify generated assets are up to date")
    args = parser.parse_args()

    if args.check:
        return check_assets()

    write_assets(ROOT)
    print("Botanical watercolor bitmap assets regenerated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())

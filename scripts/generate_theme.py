#!/usr/bin/env python3
"""Generates a dark and light base16 theme pair from a wallpaper.

A pywal backend only extracts candidate colors; the palette itself is built
in OKLCH (a perceptual space, so equal lightness looks equally light at every
hue), Material-style:

- Seed: each candidate is weighed by how much of the image shares its hue and
  by its chroma (Material's scoring), and the best one becomes the primary
  accent (base0F, which the theme's `accent` points at).
- Neutrals (base00-base07): a fixed lightness ramp, tinted with the image's
  overall color cast.
- Accents (base08-base0E): each slot keeps its meaning (red stays red for
  errors), but takes its hue from a wallpaper color near it, or else is
  rotated slightly toward the seed (Material's harmonize). Lightness and chroma
  come from fixed per-hue targets, scaled by how colorful the image is.

The lightness/chroma/hue targets are measured from the hand-made themes in
config/themes (Catppuccin, Tokyo Night, Gruvbox, Solarized), so generated
themes sit in the same range.
"""
import argparse
import importlib
import json
import logging
import math
import sys
from datetime import datetime, timezone
from pathlib import Path

import numpy as np
from PIL import Image

BACKENDS = ["wal", "colorz", "colorthief", "haishoku"]

# Semantic -> base16 maps, shared with the shell (config/json/theme-defaults.json)
_DEFAULTS = json.loads((Path(__file__).resolve().parent.parent / "config" / "json" / "theme-defaults.json").read_text())
SEMANTIC_MAP = _DEFAULTS["semantic"]["dark"]  # background = base00, as every hand-made theme orders it

# --- Palette targets (OKLCH: L 0-1, C ~0-0.37, H degrees) ---

# Neutral ramp lightness, base00 -> base07 (light themes run light -> dark)
NEUTRAL_L = {
    "dark": [0.235, 0.305, 0.385, 0.48, 0.745, 0.86, 0.91, 0.965],
    "light": [0.965, 0.93, 0.865, 0.80, 0.62, 0.44, 0.34, 0.25],
}
# How much of the neutral tint each ramp step carries (text is less tinted)
NEUTRAL_TINT = [0.9, 1.0, 1.05, 1.1, 0.85, 0.75, 0.5, 0.3]

# slot: (canonical hue, allowed hue deviation, dark L, dark C, light L, light C)
ACCENTS = {
    "base08": (20, 14, 0.735, 0.145, 0.535, 0.175),   # red: error
    "base09": (50, 12, 0.80, 0.125, 0.61, 0.150),     # orange
    "base0A": (82, 14, 0.855, 0.105, 0.70, 0.140),    # yellow: warning
    "base0B": (135, 25, 0.825, 0.125, 0.61, 0.140),   # green: success
    "base0C": (195, 30, 0.835, 0.095, 0.58, 0.100),   # cyan: info
    "base0D": (255, 25, 0.745, 0.125, 0.53, 0.160),   # blue
    "base0E": (315, 30, 0.77, 0.125, 0.54, 0.160),    # magenta
}
# Dark yellows read olive, so light themes lean amber (as Latte and Gruvbox Light do)
LIGHT_HUE_SHIFT = {"base0A": -10}
# Tint shows more on a light background
LIGHT_TINT = 0.7

PRIMARY = "base0F"
PRIMARY_L = {"dark": 0.80, "light": 0.50}
PRIMARY_C = {"dark": (0.09, 0.16), "light": (0.11, 0.19)}  # clamp range for the seed's chroma

# Slots accentAlt may point at: red would read as an error
ALT_SLOTS = ["base09", "base0A", "base0B", "base0C", "base0D", "base0E"]

MIN_CHROMA = 0.035       # below this a color counts as grey
SEED_MIN_CHROMA = 0.05   # Material's cutoff (15 CAM16 chroma) for a seed
HARMONIZE_MAX = 15.0     # Material's cap on rotating a hue toward the seed
REFERENCE_CHROMA = 0.06  # image colorfulness the accent chroma targets assume


# --- OKLab <-> sRGB ---

def _to_linear(c):
    return np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)


def _from_linear(c):
    return np.where(c <= 0.0031308, c * 12.92, 1.055 * np.abs(c) ** (1 / 2.4) - 0.055)


_RGB_TO_LMS = np.array([[0.4122214708, 0.5363325363, 0.0514459929],
                        [0.2119034982, 0.6806995451, 0.1073969566],
                        [0.0883024619, 0.2817188376, 0.6299787005]])
_LMS_TO_LAB = np.array([[0.2104542553, 0.7936177850, -0.0040720468],
                        [1.9779984951, -2.4285922050, 0.4505937099],
                        [0.0259040371, 0.7827717662, -0.8086757660]])
_LAB_TO_LMS = np.linalg.inv(_LMS_TO_LAB)
_LMS_TO_RGB = np.linalg.inv(_RGB_TO_LMS)


def srgb_to_oklab(rgb):
    """(..., 3) sRGB in 0-1 -> (..., 3) OKLab."""
    lms = _to_linear(np.asarray(rgb, dtype=float)) @ _RGB_TO_LMS.T
    return np.cbrt(lms) @ _LMS_TO_LAB.T


def oklab_to_srgb(lab):
    """(..., 3) OKLab -> (..., 3) sRGB, unclipped (out of gamut outside 0-1)."""
    lms = (np.asarray(lab, dtype=float) @ _LAB_TO_LMS.T) ** 3
    return _from_linear(lms @ _LMS_TO_RGB.T)


def lab_to_lch(lab):
    lab = np.asarray(lab, dtype=float)
    return lab[..., 0], np.hypot(lab[..., 1], lab[..., 2]), np.degrees(np.arctan2(lab[..., 2], lab[..., 1])) % 360


def hex_to_rgb(hex_val):
    h = hex_val.strip().lstrip("#")
    return np.array([int(h[i:i + 2], 16) for i in (0, 2, 4)]) / 255


def lch_to_hex(L, C, H):
    """OKLCH -> hex, reducing chroma (keeping lightness and hue) to fit sRGB."""
    def rgb(c):
        h = math.radians(H)
        return oklab_to_srgb([L, c * math.cos(h), c * math.sin(h)])

    if not np.all((rgb(C) >= -1e-4) & (rgb(C) <= 1 + 1e-4)):
        lo, hi = 0.0, C
        for _ in range(24):
            mid = (lo + hi) / 2
            r = rgb(mid)
            if np.all((r >= -1e-4) & (r <= 1 + 1e-4)):
                lo = mid
            else:
                hi = mid
        C = lo
    r = np.clip(rgb(C), 0, 1)
    return "#" + "".join(f"{round(v * 255):02x}" for v in r)


def hue_diff(a, b):
    """Signed shortest rotation from hue a to hue b, in degrees."""
    return (b - a + 180) % 360 - 180


def relative_luminance(hex_val):
    return float(_to_linear(hex_to_rgb(hex_val)) @ np.array([0.2126, 0.7152, 0.0722]))


def contrast(a, b):
    la, lb = sorted((relative_luminance(a), relative_luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


# --- Extraction ---

def extract_candidates(wallpaper, backend):
    """The backend's raw colors (before pywal's own palette adjustment)."""
    logging.disable(logging.CRITICAL)
    try:
        module = importlib.import_module(f"pywal.backends.{backend}")
        colors = module.gen_colors(str(wallpaper))
    except SystemExit:  # pywal backends exit when their package is missing
        raise RuntimeError(f"the '{backend}' backend's package is not installed (run scripts/setup_venv.sh)")
    finally:
        logging.disable(logging.NOTSET)
    colors = [c for c in colors if isinstance(c, str) and c.startswith("#")]
    if not colors:
        raise RuntimeError(f"the '{backend}' backend returned no colors")
    return list(dict.fromkeys(c.lower() for c in colors))


def load_pixels(wallpaper):
    """The image downscaled (Material quantizes ~128px too), as OKLab pixels."""
    with Image.open(wallpaper) as img:
        img = img.convert("RGB")
        img.thumbnail((128, 128))
        return srgb_to_oklab(np.asarray(img, dtype=float).reshape(-1, 3) / 255)


class Analysis:
    """What the palette needs to know about the image and its candidates."""

    def __init__(self, pixels, candidates):
        self.candidates = candidates
        lab = srgb_to_oklab(np.array([hex_to_rgb(c) for c in candidates]))
        self.L, self.C, self.H = lab_to_lch(lab)

        # Population: the share of pixels nearest each candidate
        dist = ((pixels[:, None, :] - lab[None, :, :]) ** 2).sum(axis=2)
        self.population = np.bincount(dist.argmin(axis=1), minlength=len(candidates)) / len(pixels)

        _, pc, ph = lab_to_lch(pixels)
        chromatic = pc >= MIN_CHROMA
        # Material's "excited proportion": the share of chromatic pixels within
        # 15 degrees of each candidate's hue
        self.hue_share = np.array([
            (chromatic & (np.abs(hue_diff(h, ph)) <= 15)).mean() for h in self.H
        ])
        self.colorfulness = float(pc.mean())
        # The image's overall cast: the mean a/b of every pixel
        mean_ab = pixels[:, 1:].mean(axis=0)
        self.cast_chroma = float(np.hypot(*mean_ab))
        self.cast_hue = float(math.degrees(math.atan2(mean_ab[1], mean_ab[0])) % 360)

    def scores(self):
        """Material's seed score (chroma rescaled from CAM16 to OKLCH units)."""
        chroma_cam = self.C * 400
        chroma_score = (chroma_cam - 48) * np.where(chroma_cam < 48, 0.1, 0.3)
        score = self.hue_share * 70 + chroma_score
        viable = (self.C >= SEED_MIN_CHROMA) & (self.hue_share >= 0.01)
        return np.where(viable, score, -np.inf)

    def seeds(self):
        """Candidate indices, best first, each at least 15 degrees from the ones before."""
        scores = self.scores()
        picked = []
        for i in np.argsort(-scores):
            if scores[i] == -np.inf:
                break
            if all(abs(hue_diff(self.H[i], self.H[j])) >= 15 for j in picked):
                picked.append(int(i))
        return picked


# --- Palette ---

def build_palette(analysis):
    """Both variants' base16 colors, plus the accentAlt slot and the seed."""
    seeds = analysis.seeds()
    if seeds:
        seed = seeds[0]
        seed_h, seed_c = float(analysis.H[seed]), float(analysis.C[seed])
        seed_hex = analysis.candidates[seed]
    else:
        # A grey image: take the cast's hue, with barely any color
        seed_h, seed_c, seed_hex = analysis.cast_hue, MIN_CHROMA, None

    # A second, distinct wallpaper hue for accentAlt, else Material's tertiary
    alt_h = next((float(analysis.H[i]) for i in seeds[1:]
                  if abs(hue_diff(seed_h, analysis.H[i])) >= 40), (seed_h + 60) % 360)

    # Accent chroma follows how colorful the image is, within reason
    vivid = min(max((analysis.colorfulness / REFERENCE_CHROMA) ** 0.5, 0.7), 1.15)
    if not seeds:
        vivid = 0.7

    # The neutrals take the image's cast, or the seed's hue when it has none
    neutral_h = analysis.cast_hue if analysis.cast_chroma >= 0.008 else seed_h
    tint = min(max(0.008 + analysis.cast_chroma * 0.5 + seed_c * 0.06, 0.008), 0.034)

    hues = {slot: accent_hue(slot, analysis, seed_h) for slot in ACCENTS}
    alt_slot = min(ALT_SLOTS, key=lambda s: abs(hue_diff(hues[s], alt_h)))

    palettes = {}
    for variant in ("dark", "light"):
        colors = {}
        light = variant == "light"
        for i, (L, t) in enumerate(zip(NEUTRAL_L[variant], NEUTRAL_TINT)):
            colors[f"base0{i:X}"] = lch_to_hex(L, tint * t * (LIGHT_TINT if light else 1), neutral_h)

        for slot, (_, _, dark_l, dark_c, light_l, light_c) in ACCENTS.items():
            L, C = (light_l, light_c) if light else (dark_l, dark_c)
            H = hues[slot] + (LIGHT_HUE_SHIFT.get(slot, 0) if light else 0)
            colors[slot] = readable(L, C * vivid, H, colors["base00"], variant)

        lo, hi = PRIMARY_C[variant]
        colors[PRIMARY] = readable(PRIMARY_L[variant], min(max(seed_c, lo), hi), seed_h, colors["base00"], variant)
        palettes[variant] = colors

    return palettes, alt_slot, seed_hex


def accent_hue(slot, analysis, seed_h):
    """A wallpaper hue near the slot's, if there is one, else the slot's own
    hue rotated toward the seed (Material's harmonize)."""
    canonical, deviation = ACCENTS[slot][:2]
    near = [(analysis.population[i] * analysis.C[i], float(analysis.H[i]))
            for i in range(len(analysis.candidates))
            if analysis.C[i] >= MIN_CHROMA * 1.5 and abs(hue_diff(canonical, analysis.H[i])) <= deviation]
    if near:
        return max(near)[1]
    shift = hue_diff(canonical, seed_h)
    rotation = math.copysign(min(abs(shift) * 0.5, HARMONIZE_MAX, deviation), shift)
    return (canonical + rotation) % 360


def readable(L, C, H, background, variant, minimum=3.0):
    """The color, with its lightness pushed away from the background until it
    reaches `minimum` contrast (WCAG) against it."""
    step = 0.02 if variant == "dark" else -0.02
    color = lch_to_hex(L, C, H)
    while contrast(color, background) < minimum and 0.05 < L < 0.98:
        L += step
        color = lch_to_hex(L, C, H)
    return color


# --- Output ---

def theme_json(variant, colors, alt_slot, paired, generated, backend):
    semantic = dict(SEMANTIC_MAP, accent=PRIMARY, borderFocus=PRIMARY, accentAlt=alt_slot)
    return {
        "name": f"Pywal {backend.capitalize()} {variant.capitalize()}",
        "author": "pywal",
        "variant": variant,
        "paired": paired,
        "generated": generated,
        "colors": dict(sorted(colors.items())),
        "semantic": semantic,
    }


def generate(wallpaper, pixels, output_dir, backend):
    analysis = Analysis(pixels, extract_candidates(wallpaper, backend))
    palettes, alt_slot, seed = build_palette(analysis)

    generated = {
        "source": "pywal", "backend": backend, "wallpaper": str(Path(wallpaper).resolve()),
        "seed": seed,
        "timestamp": datetime.now(timezone.utc).isoformat().replace("+00:00", "Z"),
    }
    dark, light = f"pywal-dark-{backend}", f"pywal-light-{backend}"
    for variant, name, paired in (("dark", dark, light), ("light", light, dark)):
        path = output_dir / f"{name}.json"
        path.write_text(json.dumps(theme_json(variant, palettes[variant], alt_slot, paired, generated, backend), indent=2) + "\n")
        print(f"Wrote {path}")
    return palettes


def preview(backend, palettes):
    """Truecolor swatches of both variants, for tuning in a terminal."""
    def block(hex_val):
        r, g, b = (round(v * 255) for v in hex_to_rgb(hex_val))
        return f"\x1b[48;2;{r};{g};{b}m    \x1b[0m"

    for variant, colors in palettes.items():
        keys = sorted(colors)
        print(f"{backend:>10} {variant:5} " + "".join(block(colors[k]) for k in keys[:8])
              + "  " + "".join(block(colors[k]) for k in keys[8:]))


def main():
    parser = argparse.ArgumentParser(description="Generate dark and light base16 themes from a wallpaper.")
    parser.add_argument("wallpaper", nargs="?", help="Path to the wallpaper image.")
    parser.add_argument("--output_dir", help="Directory to write the generated JSON themes to.")
    parser.add_argument("--backend", nargs="+", default=BACKENDS, choices=BACKENDS,
                        help="The pywal backend(s) that extract the candidate colors (default: all).")
    parser.add_argument("--preview", action="store_true", help="Print the palettes as terminal swatches.")
    parser.add_argument("--list-backends", action="store_true", help="List the installed backends and exit.")
    args = parser.parse_args()

    if args.list_backends:
        logging.disable(logging.CRITICAL)
        for backend in BACKENDS:
            try:
                importlib.import_module(f"pywal.backends.{backend}")
                print(f"  - {backend}")
            except SystemExit:  # pywal backends exit when their package is missing
                print(f"  - {backend} (not installed)")
        return
    if not args.wallpaper or not args.output_dir:
        parser.error("wallpaper and --output_dir are required")

    output_dir = Path(args.output_dir)
    output_dir.mkdir(parents=True, exist_ok=True)
    pixels = load_pixels(args.wallpaper)

    # One failing backend doesn't stop the others; only all of them failing does
    failed = 0
    for backend in args.backend:
        try:
            palettes = generate(args.wallpaper, pixels, output_dir, backend)
            if args.preview:
                preview(backend, palettes)
        except Exception as e:
            failed += 1
            print(f"Backend '{backend}' failed: {e}", file=sys.stderr)
    if failed == len(args.backend):
        sys.exit(1)


if __name__ == "__main__":
    main()

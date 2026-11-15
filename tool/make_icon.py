"""Generates the Joint+ app icon from a small set of geometric rules.

Grid: the 1024 px canvas is 8 x 8 units (u = 128 px).
  - The plus spans 5u, with bars 1u wide (1.5u margin on each side).
  - Joint: a green disc of diameter phi*u (golden ratio) in the centre.
  - A black gap of u/4 around the disc splits the plus into four "bones".

Outputs (assets/icon/):
  icon.svg             vector source
  icon.png             1024 px, opaque black background (iOS + legacy Android)
  icon_foreground.png  1024 px, transparent, scaled into the Android adaptive safe zone

Run: python3 tool/make_icon.py   (from the project root)
"""
import math
import sys
from pathlib import Path

from PIL import Image, ImageDraw

S = 1024
U = S / 8
PHI = (1 + 5 ** 0.5) / 2
SPAN = 5 * U                 # full width of the plus
BAR = U                      # bar thickness
R_JOINT = PHI * U / 2        # green disc radius
GAP = U / 4                  # black ring between disc and bars
R_CUT = R_JOINT + GAP

BLACK = (0, 0, 0, 255)
WHITE = (255, 255, 255, 255)
GREEN = (0, 230, 118, 255)   # #00E676, the app's accent
CLEAR = (0, 0, 0, 0)

SS = 4                       # supersampling for clean anti-aliased edges

# Android adaptive icons: the launcher mask keeps a circle of 66% of the canvas.
# Scale the glyph so its farthest corner sits well inside that circle.
ANDROID_SCALE = 0.8


def draw_glyph(img, scale, cut_fill):
    d = ImageDraw.Draw(img)
    k = SS * scale
    c = S * SS / 2
    half_span, half_bar = SPAN / 2 * k, BAR / 2 * k
    d.rectangle([c - half_span, c - half_bar, c + half_span, c + half_bar], fill=WHITE)
    d.rectangle([c - half_bar, c - half_span, c + half_bar, c + half_span], fill=WHITE)
    rc, rj = R_CUT * k, R_JOINT * k
    d.ellipse([c - rc, c - rc, c + rc, c + rc], fill=cut_fill)
    d.ellipse([c - rj, c - rj, c + rj, c + rj], fill=GREEN)


def render(bg, scale, cut_fill):
    img = Image.new("RGBA", (S * SS, S * SS), bg)
    draw_glyph(img, scale, cut_fill)
    return img.resize((S, S), Image.LANCZOS)


def svg():
    c, hs, hb = S / 2, SPAN / 2, BAR / 2
    return f"""<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {S} {S}">
  <!-- 8x8 grid, u={U:g}px. Plus 5u wide, bars 1u; joint diameter phi*u; gap u/4. -->
  <rect width="{S}" height="{S}" fill="#000"/>
  <rect x="{c-hs:g}" y="{c-hb:g}" width="{SPAN:g}" height="{BAR:g}" fill="#fff"/>
  <rect x="{c-hb:g}" y="{c-hs:g}" width="{BAR:g}" height="{SPAN:g}" fill="#fff"/>
  <circle cx="{c:g}" cy="{c:g}" r="{R_CUT:.3f}" fill="#000"/>
  <circle cx="{c:g}" cy="{c:g}" r="{R_JOINT:.3f}" fill="#00E676"/>
</svg>
"""


def main(out_dir):
    out = Path(out_dir)
    out.mkdir(parents=True, exist_ok=True)
    (out / "icon.svg").write_text(svg())
    render(BLACK, 1.0, BLACK).convert("RGB").save(out / "icon.png")
    # Foreground is transparent, so the cut ring must be transparent too
    # (the black adaptive background shows through).
    render(CLEAR, ANDROID_SCALE, CLEAR).save(out / "icon_foreground.png")

    corner = math.hypot(SPAN / 2, BAR / 2) * ANDROID_SCALE
    print(f"u={U:g}px  joint r={R_JOINT:.1f}  cut r={R_CUT:.1f}  "
          f"android corner r={corner:.0f} (safe zone r={S*0.33:.0f})")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "assets/icon")

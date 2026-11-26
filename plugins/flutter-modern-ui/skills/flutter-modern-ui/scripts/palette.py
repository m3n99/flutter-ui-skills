#!/usr/bin/env python3
"""Check, rank and apply color palettes for a Flutter UI.

For when the user has no brand color: palettes found on real palette sites
(Color Hunt, Coolors, Figma's palette pages, Realtime Colors, Adobe Color,
Huemint, Happy Hues) or in the curated fallback library are read here,
given UI roles, checked, ranked, previewed and turned into AppThemeConfig.
How to search for them: references/color.md.

    # Each argument is one candidate: a palette URL or hex codes.
    python3 palette.py https://coolors.co/264653-2a9d8f-e9c46a-f4a261-e76f51 \\
        https://colorhunt.co/palette/f9f7f7dbe2ef3f72af112d4e \\
        "https://www.realtimecolors.com/?colors=1b1b1e-faf9f6-1f4e79-d9e4ec-c8963e" \\
        "#1F2A44 #F7F5EF #1F4E79 #C8963E"

    python3 palette.py --file candidates.txt                # one candidate per line
    python3 palette.py --curated calm finance               # the offline library, by tag
    python3 palette.py ... --preview palettes.png           # light and dark mock-ups to show the user
    python3 palette.py ... --pick 2 --dart                  # AppThemeConfig for candidate 2
    python3 palette.py ... --pick 2 --design-md             # the DESIGN.md › Color block
    python3 palette.py --check-curated                      # CI: every curated palette passes

Read from the URL itself, no network needed:
  coolors.co/<hex>-<hex>-…                 (also /palette/ and /app/ forms)
  colorhunt.co/palette/<24 hex digits>     four colors
  realtimecolors.com/?colors=<text>-<bg>-<primary>-<secondary>-<accent>
For a page that holds the hex codes in its text (a Figma palette page, an
Adobe Color palette, a design system's docs), pass the hex codes, or save
the page text and pass it with --file: every #rrggbb in a line is read.

Roles. A UI needs two neutrals and one or two colors, not five equal ones:
  ink        text and icons (the darkest color)
  paper      the background (the lightest)
  primary    buttons, selected states, links (the seed)
  secondary  quieter buttons, chips, info cards (optional)
  accent     highlights, a badge, a chart series (optional; tertiary)
Realtime Colors links carry their roles. Otherwise they're assigned by
lightness and chroma, and a missing ink or paper is made from the
primary's hue (said in the report). --roles names them in order, e.g.
--roles paper,primary,accent,ink.

Checks (WCAG 2.2 contrast, light mode; dark mode comes from Material's
tonal palettes, so the Flutter contrast test is the final word):
  ink on paper ≥ 7 (≥ 4.5 required)    primary on paper ≥ 4.5 (text buttons, links)
  label on primary ≥ 4.5               accent on paper ≥ 3 (icons, chart marks)
  ink on a light secondary ≥ 4.5 (chips, info cards)
and warnings: the generated-app purple/indigo, a primary that reads as an
error, a neon primary that glares in dark mode, a poster palette with too
many loud colors. Palettes from real sources rank before the curated
fallback library when both pass. A primary or accent too light for its job is darkened
(same hue) and the report says from what to what; the original stays
available for illustrations.

Previews need Pillow for PNG (pip install pillow); without it --preview
writes an SVG. The dark mock-up is an approximation of what Material will
derive; render the app to see the real one.
"""

import argparse
import json
import math
import re
import sys
from pathlib import Path

CURATED = Path(__file__).resolve().parent.parent / "assets" / "palettes" / "curated.json"

ROLE_ORDER = ["ink", "paper", "primary", "secondary", "accent"]

# Seeds generated apps land on with no brand behind them (identity.md › defaults).
DEFAULT_SEEDS = {"6750A4", "673AB7", "3F51B5", "4F46E5", "6366F1", "7C3AED", "8B5CF6", "2196F3", "5E35B1", "512DA8"}

# "#RRGGBB" anywhere (page text runs codes into the next word: "#EE2835Copy"),
# or six hex digits standing alone.
HEX = re.compile(r"#([0-9A-Fa-f]{6})|(?<![0-9A-Fa-f#])([0-9A-Fa-f]{6})(?![0-9A-Fa-f])")


# ---------------------------------------------------------------- color math

def hex_to_rgb(hex_code):
    h = hex_code.lstrip("#")
    return tuple(int(h[i:i + 2], 16) / 255 for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "".join(f"{round(max(0, min(1, c)) * 255):02X}" for c in rgb)


def _linear(c):
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def _gamma(c):
    return 12.92 * c if c <= 0.0031308 else 1.055 * c ** (1 / 2.4) - 0.055


def luminance(hex_code):
    r, g, b = (_linear(c) for c in hex_to_rgb(hex_code))
    return 0.2126 * r + 0.7152 * g + 0.0722 * b


def contrast(a, b):
    la, lb = luminance(a), luminance(b)
    hi, lo = max(la, lb), min(la, lb)
    return (hi + 0.05) / (lo + 0.05)


def to_oklch(hex_code):
    r, g, b = (_linear(c) for c in hex_to_rgb(hex_code))
    l_ = (0.4122214708 * r + 0.5363325363 * g + 0.0514459929 * b) ** (1 / 3)
    m_ = (0.2119034982 * r + 0.6806995451 * g + 0.1073969566 * b) ** (1 / 3)
    s_ = (0.0883024619 * r + 0.2817188376 * g + 0.6299787005 * b) ** (1 / 3)
    L = 0.2104542553 * l_ + 0.7936177850 * m_ - 0.0040720468 * s_
    a = 1.9779984951 * l_ - 2.4285922050 * m_ + 0.4505937099 * s_
    bb = 0.0259040371 * l_ + 0.7827717662 * m_ - 0.8086757660 * s_
    C = math.hypot(a, bb)
    H = math.degrees(math.atan2(bb, a)) % 360
    return L, C, H


def _oklch_to_linear(L, C, H):
    a, b = C * math.cos(math.radians(H)), C * math.sin(math.radians(H))
    l_ = (L + 0.3963377774 * a + 0.2158037573 * b) ** 3
    m_ = (L - 0.1055613458 * a - 0.0638541728 * b) ** 3
    s_ = (L - 0.0894841775 * a - 1.2914855480 * b) ** 3
    return (
        4.0767416621 * l_ - 3.3077115913 * m_ + 0.2309699292 * s_,
        -1.2684380046 * l_ + 2.6097574011 * m_ - 0.3413193965 * s_,
        -0.0041960863 * l_ - 0.7034186147 * m_ + 1.7076147010 * s_,
    )


def from_oklch(L, C, H):
    """The nearest sRGB color: chroma is reduced until it fits."""
    L = max(0.0, min(1.0, L))
    for _ in range(40):
        rgb = _oklch_to_linear(L, C, H)
        if all(-1e-4 <= c <= 1 + 1e-4 for c in rgb):
            break
        C *= 0.92
    return rgb_to_hex(tuple(_gamma(max(0.0, min(1.0, c))) for c in rgb))


def hue_distance(a, b):
    d = abs(a - b) % 360
    return min(d, 360 - d)


def darken_to(hex_code, against, target):
    """[hex_code] with its lightness moved (same hue) until it reaches
    [target]:1 against [against]; None if it already does."""
    if contrast(hex_code, against) >= target:
        return None
    L, C, H = to_oklch(hex_code)
    darker = luminance(against) > 0.18
    for step in range(1, 100):
        candidate = from_oklch(L - step * 0.01 if darker else L + step * 0.01, C, H)
        if contrast(candidate, against) >= target:
            return candidate
    return None


def best_label(on, ink, paper):
    """The label color for text on [on]: white, the ink or the paper,
    whichever reads best."""
    options = [("FFFFFF", "white"), (ink, "ink"), (paper, "paper")]
    return max(options, key=lambda option: contrast(option[0], on))


# ---------------------------------------------------------------- reading

def parse_candidate(text):
    """(hex list, roles dict or None, source url or None) from one argument."""
    text = text.strip()
    url = text if re.match(r"https?://", text) else None
    match = re.search(r"realtimecolors\.com/?\?(?:[^#]*&)?colors=([0-9A-Fa-f-]+)", text)
    if match:
        hexes = [h.upper() for h in match.group(1).split("-") if len(h) == 6]
        roles = dict(zip(["ink", "paper", "primary", "secondary", "accent"], hexes))
        # A dark Realtime Colors palette: its text is the light color.
        if "ink" in roles and "paper" in roles and luminance(roles["ink"]) > luminance(roles["paper"]):
            roles["ink"], roles["paper"] = roles["paper"], roles["ink"]
        return hexes, roles, url
    match = re.search(r"colorhunt\.co/palette/([0-9A-Fa-f]{12,48})", text)
    if match:
        digits = match.group(1)
        return [digits[i:i + 6].upper() for i in range(0, len(digits) - len(digits) % 6, 6)], None, url
    match = re.search(r"coolors\.co/(?:palette/|app/)?([0-9A-Fa-f]{6}(?:-[0-9A-Fa-f]{6})+)", text)
    if match:
        return [h.upper() for h in match.group(1).split("-")], None, url
    hexes = []
    for marked, bare in HEX.findall(text):
        found = (marked or bare).upper()
        if found not in hexes:
            hexes.append(found)
    return hexes, None, url


def assign_roles(hexes, given=None, order=None):
    """Roles for a list of colors, and notes on what was assumed or made."""
    notes = []
    if order:
        roles = {role: h for role, h in zip(order, hexes)}
    elif given:
        roles = dict(given)
    else:
        roles = {}
        rest = list(hexes)
        by_l = sorted(rest, key=lambda h: to_oklch(h)[0])
        lightest, darkest = by_l[-1], by_l[0]
        Ll, Cl, _ = to_oklch(lightest)
        Ld, Cd, _ = to_oklch(darkest)
        if Ll >= 0.9 and Cl <= 0.06 and len(rest) > 1:
            roles["paper"] = lightest
            rest.remove(lightest)
        if Ld <= 0.38 and Cd <= 0.12 and darkest in rest and len(rest) > 1:
            roles["ink"] = darkest
            rest.remove(darkest)
        if rest:
            paper = roles.get("paper", "FAFAF8")

            def primary_score(h):
                L, C, H = to_oklch(h)
                # Carries text and buttons as it is; a red would read as an error.
                usable = 1.15 if contrast(h, paper) >= 4.5 else (1.0 if contrast(h, paper) >= 3 else 0.55)
                reddish = 0.6 if 10 <= H <= 40 and C >= 0.12 else 1.0
                middle = 1 - min(1, abs(L - 0.5) / 0.5)
                return (min(C, 0.2) + 0.02) * usable * reddish * (0.6 + 0.4 * middle)

            roles["primary"] = max(rest, key=primary_score)
            rest.remove(roles["primary"])
        if rest:
            ph = to_oklch(roles["primary"])[2]
            loud = [h for h in rest if to_oklch(h)[1] >= 0.06]
            if loud:
                roles["accent"] = max(loud, key=lambda h: hue_distance(to_oklch(h)[2], ph) * to_oklch(h)[1])
                rest.remove(roles["accent"])
        if rest:
            roles["secondary"] = max(rest, key=lambda h: to_oklch(h)[1])
            rest.remove(roles["secondary"])
        if rest:
            notes.append(f"not used in the UI: {', '.join('#' + h for h in rest)} (illustrations, charts)")
    if "primary" not in roles:
        raise ValueError("no color left for primary")
    _, pc, ph = to_oklch(roles["primary"])
    if "paper" not in roles:
        roles["paper"] = from_oklch(0.975, min(0.012, pc), ph)
        notes.append(f"paper made from the primary's hue: #{roles['paper']}")
    if "ink" not in roles:
        roles["ink"] = from_oklch(0.22, min(0.03, pc), ph)
        notes.append(f"ink made from the primary's hue: #{roles['ink']}")
    return roles, notes


# ---------------------------------------------------------------- judging

class Candidate:
    def __init__(self, label, hexes, roles, notes, source=None, name=None, tags=(), why=None):
        self.label = label
        self.hexes = hexes
        self.roles = roles
        self.notes = list(notes)
        self.source = source
        self.name = name
        self.tags = list(tags)
        self.why = why
        self.checks = []  # (name, ratio, minimum, passed, hard)
        self.warnings = []
        self.fixed = {}  # role -> (original, adjusted)
        self.score = 0.0
        self.judge()

    def ui(self, role):
        return self.fixed[role][1] if role in self.fixed else self.roles.get(role)

    def judge(self):
        r = self.roles
        ink, paper, primary = r["ink"], r["paper"], r["primary"]

        adjusted = darken_to(primary, paper, 4.5)
        if adjusted:
            self.fixed["primary"] = (primary, adjusted)
            self.notes.append(
                f"primary #{primary} is {contrast(primary, paper):.1f}:1 on paper, too light for text and buttons: "
                f"use #{adjusted} (same hue); keep #{primary} for illustrations"
            )
        accent = r.get("accent")
        if accent:
            adjusted = darken_to(accent, paper, 3)
            if adjusted:
                self.fixed["accent"] = (accent, adjusted)
                self.notes.append(f"accent #{accent} is {contrast(accent, paper):.1f}:1 on paper: use #{adjusted} for icons and marks")

        p = self.ui("primary")
        label_hex, label_name = best_label(p, ink, paper)
        self.label_on_primary = (label_hex, label_name)

        def check(name, ratio, minimum, hard=True):
            self.checks.append((name, ratio, minimum, ratio >= minimum, hard))

        check("ink on paper (body text)", contrast(ink, paper), 4.5)
        check("primary on paper (text buttons, links)", contrast(p, paper), 4.5)
        check(f"{label_name} label on primary (filled buttons)", contrast(label_hex, p), 4.5)
        if accent:
            check("accent on paper (icons, chart marks)", contrast(self.ui("accent"), paper), 3)
        secondary = r.get("secondary")
        if secondary:
            # A light secondary is a fill (chips, info cards) with ink on it.
            if to_oklch(secondary)[0] >= 0.72:
                check("ink on secondary (chips, info cards)", contrast(ink, secondary), 4.5)
            else:
                check("secondary on paper (quiet buttons)", contrast(secondary, paper), 3, hard=False)

        L, C, H = to_oklch(p)
        if primary.upper() in DEFAULT_SEEDS or (265 <= H <= 310 and C >= 0.08):
            self.warnings.append("primary is the purple/indigo generated apps default to: keep it only if the brief asks for it")
        if 10 <= H <= 40 and C >= 0.12:
            self.warnings.append("primary reads as red: errors and Delete need a clearly different tone (AppPalette, error)")
        if C >= 0.24:
            self.warnings.append("primary is near neon: fine for an accent, tiring as the main color, and it glares in dark mode")
        loud = [h for h in self.hexes if to_oklch(h)[1] >= 0.12]
        if len(loud) >= 4:
            self.warnings.append(f"{len(loud)} loud colors: a poster palette. Use one as primary, at most one as accent, the rest in illustrations only")
        if contrast(ink, paper) < 7:
            self.warnings.append("body text under 7:1 on the background: readable, but tiring in long sessions")
        if accent and hue_distance(to_oklch(accent)[2], H) < 25 and to_oklch(accent)[1] >= 0.06:
            self.warnings.append("accent is close in hue to primary: it won't stand out as a highlight")

        hard_failures = sum(1 for c in self.checks if c[4] and not c[3])
        margin = sum(min(c[1] / c[2], 2.0) for c in self.checks) / max(1, len(self.checks))
        default_look = any("purple/indigo" in w for w in self.warnings)
        made = sum(1 for n in self.notes if " made from " in n)
        self.score = round(
            100 - 30 * hard_failures - 8 * len(self.warnings) - 20 * default_look - 10 * len(self.fixed) - 3 * made + 10 * margin,
            1,
        )

    @property
    def curated(self):
        return bool(self.source and self.source.startswith("curated"))

    def rank_key(self):
        """Passing first; then palettes found on real sources before the
        fallback library; then the score."""
        return (-int(self.passed), int(self.curated), -self.score)

    @property
    def passed(self):
        return all(c[3] for c in self.checks if c[4])

    def title(self):
        return self.name or self.label

    def realtime_url(self):
        r = self.roles
        parts = [r["ink"], r["paper"], self.ui("primary"), r.get("secondary") or r["paper"], self.ui("accent") or self.ui("primary")]
        return "https://www.realtimecolors.com/?colors=" + "-".join(h.lower() for h in parts)

    def seeds(self):
        """The AppThemeConfig seeds: (field, hex, comment)."""
        out = [("seed", self.ui("primary"), "primary")]
        secondary = self.roles.get("secondary")
        if secondary and to_oklch(secondary)[1] >= 0.03:
            out.append(("secondarySeed", secondary, "secondary"))
        if self.roles.get("accent"):
            out.append(("tertiarySeed", self.ui("accent"), "accent"))
        out.append(("neutralSeed", self.roles["paper"], "paper: surfaces tinted toward its hue"))
        return out

    def to_json(self):
        return {
            "label": self.label,
            "name": self.name,
            "source": self.source,
            "roles": {k: "#" + v for k, v in self.roles.items()},
            "ui": {k: "#" + self.ui(k) for k in self.roles},
            "passed": self.passed,
            "score": self.score,
            "checks": [{"check": n, "ratio": round(r, 2), "minimum": m, "passed": p, "required": h} for n, r, m, p, h in self.checks],
            "warnings": self.warnings,
            "notes": self.notes,
            "realtimecolors": self.realtime_url(),
        }


def build(label, text, order=None, name=None, tags=(), why=None, source=None):
    hexes, given, url = parse_candidate(text)
    if not hexes:
        raise ValueError("no hex colors found")
    roles, notes = assign_roles(hexes, given, order)
    return Candidate(label, hexes, roles, notes, source=source or url, name=name, tags=tags, why=why)


def load_curated(tags=()):
    data = json.loads(CURATED.read_text(encoding="utf-8"))
    out = []
    for entry in data["palettes"]:
        if tags and not set(t.lower() for t in tags) & set(entry["tags"]):
            continue
        roles = entry["roles"]
        order = [role for role in ROLE_ORDER if role in roles]
        text = " ".join(roles[role] for role in order)
        out.append(build(entry["name"], text, order=order, name=entry["name"], tags=entry["tags"], why=entry.get("why"), source="curated (assets/palettes/curated.json)"))
    return out


# ---------------------------------------------------------------- output

def report(candidates):
    lines = []
    ranked = sorted(candidates, key=Candidate.rank_key)
    for rank, c in enumerate(ranked, 1):
        status = "passes" if c.passed else "FAILS"
        lines.append(f"{rank}. {c.title()}  [{status}, score {c.score}]  (candidate {candidates.index(c) + 1})")
        if c.source:
            lines.append(f"   source: {c.source}")
        if c.why:
            lines.append(f"   for: {c.why}")
        lines.append("   roles: " + "  ".join(f"{role} #{c.ui(role)}" for role in ROLE_ORDER if role in c.roles))
        for name, ratio, minimum, passed, hard in c.checks:
            mark = "ok " if passed else ("FAIL" if hard else "warn")
            lines.append(f"   {mark} {name}: {ratio:.2f}:1 (needs {minimum})")
        for warning in c.warnings:
            lines.append(f"   ! {warning}")
        for note in c.notes:
            lines.append(f"   · {note}")
        lines.append(f"   preview on a real page: {c.realtime_url()}")
        lines.append("")
    return "\n".join(lines).rstrip()


def dart(c):
    lines = [f"  // Palette: {c.title()}" + (f" ({c.source})" if c.source else "") + ". Checked with palette.py."]
    lines.append("  static const AppThemeConfig config = AppThemeConfig(")
    for field, hex_code, comment in c.seeds():
        lines.append(f"    {field}: Color(0xFF{hex_code}), // {comment}")
    lines.append("    // fidelity keeps the primary's exact hue; containers stay soft.")
    lines.append("    variant: DynamicSchemeVariant.fidelity,")
    lines.append("  );")
    return "\n".join(lines)


def design_md(c):
    r = c.roles
    out = [f"### Color: {c.title()}", ""]
    out.append(f"Source: {c.source or 'given by hand'}. Chosen because: {{the brief's feeling words it fits}}.")
    out.append("")
    out.append("| Role | Color | Used for |")
    out.append("|---|---|---|")
    jobs = {
        "ink": "text and icons",
        "paper": "the background; surfaces are tinted toward its hue",
        "primary": "filled and text buttons, selection, links",
        "secondary": "quiet buttons, chips, info cards",
        "accent": "highlights, one badge, a chart series (tertiary)",
    }
    for role in ROLE_ORDER:
        if role in r:
            shown = f"`#{c.ui(role)}`" + (f" (from `#{c.fixed[role][0]}`)" if role in c.fixed else "")
            out.append(f"| {role} | {shown} | {jobs[role]} |")
    out.append("")
    checks = ", ".join(f"{n.split(' (')[0]} {ratio:.1f}:1" for n, ratio, _, _, _ in c.checks)
    out.append(f"Checked: {checks}. Preview: {c.realtime_url()}")
    return "\n".join(out)


def _dark(c):
    """An approximation of the dark theme Material derives (tone 80
    primaries on tone-6 surfaces), for the preview only."""
    _, pc, ph = to_oklch(c.roles["paper"])
    _, ic, ih = to_oklch(c.roles["ink"])
    bg = from_oklch(0.19, min(0.02, max(pc, ic)), ih)
    card = from_oklch(0.235, min(0.02, max(pc, ic)), ih)
    text = from_oklch(0.92, min(0.015, pc), ph)
    muted = from_oklch(0.75, min(0.015, pc), ph)
    L, C, H = to_oklch(c.ui("primary"))
    primary = from_oklch(max(L, 0.78), min(C, 0.13), H)
    on_primary = from_oklch(0.25, min(C, 0.08), H)
    accent = c.ui("accent")
    if accent:
        La, Ca, Ha = to_oklch(accent)
        accent = from_oklch(max(La, 0.78), min(Ca, 0.14), Ha)
    secondary = from_oklch(0.32, min(0.04, C), H)
    return {"bg": bg, "card": card, "text": text, "muted": muted, "primary": primary, "on_primary": on_primary, "accent": accent, "chip": secondary}


def _light(c):
    paper, ink = c.roles["paper"], c.roles["ink"]
    Lp, Cp, Hp = to_oklch(paper)
    card = from_oklch(min(1.0, Lp + 0.02), Cp * 0.6, Hp)
    _, Cpr, Hpr = to_oklch(c.ui("primary"))
    sec = c.roles.get("secondary")
    chip = sec if sec and to_oklch(sec)[0] >= 0.72 else from_oklch(0.92, min(0.04, Cpr), Hpr)
    Li, Ci, Hi = to_oklch(ink)
    muted = from_oklch(min(0.55, Li + 0.25), Ci, Hi)
    return {"bg": paper, "card": card, "text": ink, "muted": muted, "primary": c.ui("primary"), "on_primary": c.label_on_primary[0], "accent": c.ui("accent"), "chip": chip}


def _font(size, bold=False):
    from PIL import ImageFont

    names = ["DejaVuSans-Bold.ttf", "Arial Bold.ttf", "arialbd.ttf"] if bold else ["DejaVuSans.ttf", "Arial.ttf", "arial.ttf"]
    names += ["Helvetica.ttc", "SFNS.ttf"]
    for name in names:
        try:
            return ImageFont.truetype(name, size)
        except OSError:
            continue
    try:
        return ImageFont.load_default(size)
    except TypeError:
        return ImageFont.load_default()


def preview_png(candidates, path):
    from PIL import Image, ImageDraw

    col_w, phone_w, phone_h = 560, 250, 470
    height = 150 + phone_h + 40
    image = Image.new("RGB", (col_w * len(candidates) + 40, height), (236, 236, 234))
    draw = ImageDraw.Draw(image)
    f_title, f_small, f_body, f_bold, f_big = _font(18, True), _font(12), _font(14), _font(14, True), _font(22, True)

    def rgb(h):
        return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))

    def phone(x, y, colors, mode):
        draw.rounded_rectangle((x, y, x + phone_w, y + phone_h), 22, fill=rgb(colors["bg"]), outline=(190, 190, 186))
        draw.text((x + 16, y + 10), "9:41", fill=rgb(colors["text"]), font=f_small)
        draw.text((x + 16, y + 40), "Overview", fill=rgb(colors["text"]), font=f_big)
        cy = y + 82
        draw.rounded_rectangle((x + 14, cy, x + phone_w - 14, cy + 132), 14, fill=rgb(colors["card"]))
        draw.text((x + 28, cy + 14), "To collect", fill=rgb(colors["muted"]), font=f_small)
        draw.text((x + 28, cy + 32), "$20,508.00", fill=rgb(colors["text"]), font=f_big)
        draw.text((x + 28, cy + 70), "Overdue · 2 invoices", fill=rgb(colors["muted"]), font=f_small)
        if colors["accent"]:
            draw.ellipse((x + phone_w - 46, cy + 16, x + phone_w - 30, cy + 32), fill=rgb(colors["accent"]))
        draw.rounded_rectangle((x + 28, cy + 92, x + phone_w - 28, cy + 120), 10, fill=rgb(colors["primary"]))
        label = "Send 2 reminders"
        tw = draw.textlength(label, font=f_bold)
        draw.text((x + (phone_w - tw) / 2, cy + 98), label, fill=rgb(colors["on_primary"]), font=f_bold)
        chy = cy + 150
        chx = x + 14
        for chip in ["All", "Due soon", "Paid"]:
            w = draw.textlength(chip, font=f_small) + 24
            draw.rounded_rectangle((chx, chy, chx + w, chy + 26), 13, fill=rgb(colors["chip"]) if chip == "Due soon" else None, outline=rgb(colors["muted"]) if chip != "Due soon" else None)
            draw.text((chx + 12, chy + 6), chip, fill=rgb(colors["text"]), font=f_small)
            chx += w + 8
        ry = chy + 44
        for name, amount in [("Blue Harbor Café", "$842.00"), ("Cedar Print Co.", "$175.50"), ("Kinetic Labs", "$12,500.00")]:
            draw.text((x + 22, ry), name, fill=rgb(colors["text"]), font=f_body)
            aw = draw.textlength(amount, font=f_body)
            draw.text((x + phone_w - 22 - aw, ry), amount, fill=rgb(colors["text"]), font=f_body)
            draw.line((x + 22, ry + 26, x + phone_w - 22, ry + 26), fill=rgb(colors["muted"]), width=1)
            ry += 40
        draw.text((x + 22, ry + 4), "See all invoices", fill=rgb(colors["primary"]), font=f_bold)
        draw.text((x + 14, y + phone_h - 22), mode, fill=rgb(colors["muted"]), font=f_small)

    for i, c in enumerate(candidates):
        x0 = 20 + i * col_w
        draw.text((x0, 16), f"{i + 1}. {c.title()}"[:52], fill=(20, 20, 20), font=f_title)
        src = (c.source or "hex codes given by hand")[:80]
        draw.text((x0, 42), src, fill=(90, 90, 90), font=f_small)
        sx = x0
        for role in ROLE_ORDER:
            if role not in c.roles:
                continue
            h = c.ui(role)
            draw.rounded_rectangle((sx, 66, sx + 96, 112), 8, fill=rgb(h), outline=(180, 180, 176))
            draw.text((sx, 116), role, fill=(40, 40, 40), font=f_small)
            draw.text((sx, 130), "#" + h, fill=(90, 90, 90), font=f_small)
            sx += 104
        phone(x0, 160, _light(c), "light")
        phone(x0 + phone_w + 20, 160, _dark(c), "dark (approximate)")
    image.save(path)


def preview_svg(candidates, path):
    col_w = 560
    parts = [f'<svg xmlns="http://www.w3.org/2000/svg" width="{col_w * len(candidates) + 40}" height="300" font-family="sans-serif">',
             '<rect width="100%" height="100%" fill="#ECECEA"/>']
    for i, c in enumerate(candidates):
        x0 = 20 + i * col_w
        parts.append(f'<text x="{x0}" y="30" font-size="18" font-weight="bold">{i + 1}. {c.title()}</text>')
        sx = x0
        for role in ROLE_ORDER:
            if role in c.roles:
                parts.append(f'<rect x="{sx}" y="50" width="96" height="60" rx="8" fill="#{c.ui(role)}" stroke="#B4B4B0"/>')
                parts.append(f'<text x="{sx}" y="128" font-size="12">{role}</text><text x="{sx}" y="144" font-size="12" fill="#5A5A5A">#{c.ui(role)}</text>')
                sx += 104
        l = _light(c)
        parts.append(f'<rect x="{x0}" y="170" width="250" height="110" rx="14" fill="#{l["bg"]}" stroke="#B4B4B0"/>')
        parts.append(f'<text x="{x0 + 16}" y="200" font-size="16" fill="#{l["text"]}">Overview</text>')
        parts.append(f'<rect x="{x0 + 16}" y="225" width="218" height="34" rx="10" fill="#{l["primary"]}"/>')
        parts.append(f'<text x="{x0 + 70}" y="247" font-size="14" font-weight="bold" fill="#{l["on_primary"]}">Send reminders</text>')
    parts.append("</svg>")
    Path(path).write_text("\n".join(parts), encoding="utf-8")


def preview(candidates, path):
    path = Path(path)
    if path.suffix.lower() != ".svg":
        try:
            preview_png(candidates, path)
            return path
        except ImportError:
            path = path.with_suffix(".svg")
            print("Pillow isn't installed (pip install pillow): wrote an SVG instead.", file=sys.stderr)
    preview_svg(candidates, path)
    return path


# ---------------------------------------------------------------- main


def utf8_console():
    """Arabic in the output must not stop the script: a Windows console or
    pipe defaults to the ANSI code page (cp1252), where print() of Arabic
    raises UnicodeEncodeError."""
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass


def main():
    utf8_console()
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("candidates", nargs="*", help="palette URLs or hex codes, one argument per palette")
    parser.add_argument("--file", help="a file with one candidate per line (# comments allowed after the colors)")
    parser.add_argument("--curated", nargs="*", metavar="TAG", help="add palettes from the curated library (all, or those with any of these tags)")
    parser.add_argument("--tags", action="store_true", help="list the curated library's tags and exit")
    parser.add_argument("--roles", help="the role of each color, in order: e.g. paper,primary,accent,ink")
    parser.add_argument("--pick", type=int, help="the candidate (as numbered in the input) for --dart / --design-md")
    parser.add_argument("--dart", action="store_true", help="print AppThemeConfig for the picked (or best) candidate")
    parser.add_argument("--design-md", action="store_true", help="print the DESIGN.md color block for the picked (or best) candidate")
    parser.add_argument("--preview", metavar="PATH", help="write light and dark mock-ups of the top 3 (or the picked) to a PNG (or SVG)")
    parser.add_argument("--top", type=int, default=3, help="how many candidates the preview shows (default 3)")
    parser.add_argument("--json", action="store_true", help="print the results as JSON")
    parser.add_argument("--check-curated", action="store_true", help="fail unless every curated palette passes (CI)")
    args = parser.parse_args()

    if args.tags:
        data = json.loads(CURATED.read_text(encoding="utf-8"))
        counts = {}
        for entry in data["palettes"]:
            for tag in entry["tags"]:
                counts[tag] = counts.get(tag, 0) + 1
        print(", ".join(f"{tag} ({n})" for tag, n in sorted(counts.items())))
        return 0

    if args.check_curated:
        palettes = load_curated()
        bad = [c for c in palettes if not c.passed or c.fixed or any("purple/indigo" in w for w in c.warnings)]
        for c in bad:
            print(report([c]))
        names = [c.name for c in palettes]
        if len(set(names)) != len(names):
            print("duplicate palette names")
            return 1
        print(f"{len(palettes) - len(bad)} of {len(palettes)} curated palettes pass with no adjustment")
        return 1 if bad else 0

    order = args.roles.split(",") if args.roles else None
    candidates, errors = [], []
    texts = list(args.candidates)
    if args.file:
        for line in Path(args.file).read_text(encoding="utf-8").splitlines():
            if HEX.search(line) or "colors=" in line:
                texts.append(line)
    for i, text in enumerate(texts, 1):
        try:
            candidates.append(build(f"candidate {i}", text, order))
        except ValueError as error:
            errors.append(f"candidate {i} ({text[:60]}): {error}")
    if args.curated is not None:
        candidates += load_curated(args.curated)
    for error in errors:
        print(error, file=sys.stderr)
    if not candidates:
        parser.error("give at least one palette (URL or hex codes), --file or --curated")

    ranked = sorted(candidates, key=Candidate.rank_key)
    if args.pick:
        if not 1 <= args.pick <= len(candidates):
            parser.error(f"--pick must be between 1 and {len(candidates)}")
        chosen = candidates[args.pick - 1]
    else:
        chosen = ranked[0]

    if args.json:
        print(json.dumps([c.to_json() for c in ranked], indent=2, ensure_ascii=False))
    elif not (args.dart or args.design_md):
        print(report(candidates))
    if args.dart:
        print(dart(chosen))
    if args.design_md:
        print(design_md(chosen))
    if args.preview:
        shown = [chosen] if args.pick else ranked[: args.top]
        written = preview(shown, args.preview)
        print(f"Preview: {written} ({len(shown)} palette(s), light and an approximate dark)", file=sys.stderr)
    return 0 if chosen.passed else 2


if __name__ == "__main__":
    sys.exit(main())

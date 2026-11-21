#!/usr/bin/env python3
"""CI only: palette.py reads every source's URL format, does the contrast
math right, gives roles sensibly and warns where it says it does.
Run from the repo root: python3 ci/palette_selftest.py"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "plugins/flutter-modern-ui/skills/flutter-modern-ui/scripts"))
import palette  # noqa: E402

failures = []


def expect(name, actual, expected):
    if actual != expected:
        failures.append(f"{name}: expected {expected!r}, got {actual!r}")


def expect_true(name, value):
    if not value:
        failures.append(name)


# Contrast math against known values.
expect("black on white", round(palette.contrast("000000", "FFFFFF"), 2), 21.0)
expect("#777 on white", round(palette.contrast("777777", "FFFFFF"), 2), 4.48)
expect("same color", palette.contrast("3F72AF", "3F72AF"), 1.0)
# OKLCH round trip.
for h in ["1F4E79", "F7F5EF", "E76F51", "0F766E"]:
    back = palette.from_oklch(*palette.to_oklch(h))
    expect_true(f"oklch round trip {h} -> {back}", all(abs(int(h[i:i + 2], 16) - int(back[i:i + 2], 16)) <= 1 for i in (0, 2, 4)))

# Every source's URL format.
expect("coolors", palette.parse_candidate("https://coolors.co/264653-2a9d8f-e9c46a-f4a261-e76f51")[0], ["264653", "2A9D8F", "E9C46A", "F4A261", "E76F51"])
expect("coolors /palette/", palette.parse_candidate("https://coolors.co/palette/05668d-028090-00a896")[0], ["05668D", "028090", "00A896"])
expect("coolors /app/", palette.parse_candidate("https://coolors.co/app/05668d-028090-00a896")[0], ["05668D", "028090", "00A896"])
expect("color hunt", palette.parse_candidate("https://colorhunt.co/palette/f9f7f7dbe2ef3f72af112d4e")[0], ["F9F7F7", "DBE2EF", "3F72AF", "112D4E"])
hexes, roles, _ = palette.parse_candidate("https://www.realtimecolors.com/?colors=1b1b1e-faf9f6-1f4e79-d9e4ec-c8963e&fonts=Inter-Inter")
expect("realtime colors roles", (roles["ink"], roles["paper"], roles["primary"], roles["accent"]), ("1B1B1E", "FAF9F6", "1F4E79", "C8963E"))
_, roles, _ = palette.parse_candidate("https://realtimecolors.com/?colors=e6e4ec-0b0420-c89ff4-1c1334-d3f980")
expect("dark realtime colors palette: ink and paper swap", (roles["ink"], roles["paper"]), ("0B0420", "E6E4EC"))
expect("figma page text", palette.parse_candidate("Copy Hex:#EE2835Copy Hex:#ED8171Copy Hex:#04529DCopy Hex:#3A6963")[0], ["EE2835", "ED8171", "04529D", "3A6963"])
expect("loose hex codes", palette.parse_candidate("#1f2a44, f7f5ef 1F4E79")[0], ["1F2A44", "F7F5EF", "1F4E79"])

# Roles and fixes.
c = palette.build("pastel", "https://colorhunt.co/palette/b5c0d0ccd3caf5e8ddeed3d9")
expect_true("a pastel primary is darkened to carry text", "primary" in c.fixed and palette.contrast(c.ui("primary"), c.roles["paper"]) >= 4.5)
expect_true("a missing ink is made", any("ink made from" in n for n in c.notes))
c = palette.build("figma", "#EE2835 #ED8171 #04529D #3A6963")
expect("a usable blue beats a red as primary", c.roles["primary"], "04529D")
c = palette.build("default", "#6750A4")
expect_true("default purple is flagged", any("purple/indigo" in w for w in c.warnings))
c = palette.build("red", "#C62828 #FFFFFF #1A1A1A")
expect_true("a red primary is flagged", any("reads as red" in w for w in c.warnings))
c = palette.build("poster", "https://coolors.co/ff595e-ffca3a-8ac926-1982c4-6a4c93")
expect_true("a poster palette is flagged", any("loud colors" in w for w in c.warnings))
c = palette.build("given roles", "#F7F5EF #1F4E79 #C8963E #1F2A44", order=["paper", "primary", "accent", "ink"])
expect("--roles", (c.roles["paper"], c.roles["primary"], c.roles["accent"], c.roles["ink"]), ("F7F5EF", "1F4E79", "C8963E", "1F2A44"))
expect_true("every check passes for a good palette", c.passed)
expect("seeds", [field for field, _, _ in c.seeds()], ["seed", "tertiarySeed", "neutralSeed"])
expect_true("dart output has the seed", "seed: Color(0xFF1F4E79)" in palette.dart(c))
expect_true("realtime colors link", c.realtime_url().startswith("https://www.realtimecolors.com/?colors=1f2a44-f7f5ef-1f4e79-"))

# Ranking: real sources before the curated library when both pass.
mixed = [palette.build("found", "https://colorhunt.co/palette/f9f7f7dbe2ef3f72af112d4e")] + palette.load_curated(["finance"])
expect("found palettes rank first", sorted(mixed, key=palette.Candidate.rank_key)[0].label, "found")

for failure in failures:
    print(f"FAIL {failure}")
print(f"{'failed' if failures else 'passed'}: {len(failures)} failure(s)")
sys.exit(1 if failures else 0)

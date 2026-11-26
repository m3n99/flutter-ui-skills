#!/usr/bin/env python3
"""Check that the app's fonts have a glyph for every character the UI shows.

    python3 check_glyphs.py --font assets/fonts/Tajawal-Regular.ttf --font assets/fonts/Tajawal-Bold.ttf
    python3 check_glyphs.py --font assets/fonts/Tajawal-Regular.ttf --fallback assets/fonts/NotoSans-Regular.ttf
    python3 check_glyphs.py --font ... --chars "₪٫٬" lib l10n

Collects every non-ASCII character in the string literals of .dart files and
the values of .arb files under the given paths (default: lib), adds --chars
(text the app only builds at run time, such as currency symbols, separators
and digits from intl's NumberFormat), and reports each character that a
--font file lacks: Flutter then falls back to a system font with a different
look, or draws an empty box. Characters a --fallback covers are listed as
notes (they render, in another style).

--font: the app's own family, one file per weight it uses (all must have the
glyph). --fallback: the families in fontFamilyFallback, in order.
Emoji are skipped: the system emoji font draws them.

Metrics for printing (--metrics): where text sits on a printed line.

    python3 check_glyphs.py --font calibri.ttf --metrics "تحريراً في" "12/11/2026" --size 11 13

prints, per font: ascent and descent as the pdf package reads them (hhea,
in em), the deepest glyph of each text including its contextual forms
(the tail of «ي» goes deeper than the font's own descent in some fonts),
where Arabic letters rest (the bottom of the tatweel «ـ»: 0 in most fonts,
above the baseline in Calibri), and whether the font has the Arabic forms
(alef, lam-alef) and relies on GPOS mark positioning, which the pdf package
doesn't apply (tashkeel then prints misplaced). With --size, each value is
also given in cm. See references/preprinted-forms.md.

Needs fontTools: pip install fonttools.
Exit codes: 0 every character covered, 1 error, 2 missing glyphs.
"""

import argparse
import json
import re
import sys
import unicodedata
from pathlib import Path

ESCAPE = re.compile(r"\\u\{([0-9A-Fa-f]{1,6})\}|\\u([0-9A-Fa-f]{4})")


def dart_strings(source):
    """Yield (line, text) for each string literal, skipping comments."""
    i, line, n = 0, 1, len(source)
    while i < n:
        c = source[i]
        if c == "\n":
            line += 1
            i += 1
        elif source.startswith("//", i):
            end = source.find("\n", i)
            i = n if end < 0 else end
        elif source.startswith("/*", i):
            end = source.find("*/", i + 2)
            end = n if end < 0 else end + 2
            line += source.count("\n", i, end)
            i = end
        elif c in "'\"":
            raw = i > 0 and source[i - 1] in "rR"
            quote = source[i : i + 3] if source.startswith(c * 3, i) else c
            start, j = i + len(quote), i + len(quote)
            while j < n and not source.startswith(quote, j):
                if source[j] == "\\" and not raw:
                    j += 1
                elif source[j] == "\n" and len(quote) == 1:
                    break
                j += 1
            text = source[start:j]
            if not raw:
                text = ESCAPE.sub(lambda m: chr(int(m.group(1) or m.group(2), 16)), text)
            yield line, text
            line += source.count("\n", i, j)
            i = j + len(quote)
        else:
            i += 1


def arb_strings(path):
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (ValueError, OSError):
        return
    for key, value in data.items():
        if not key.startswith("@") and isinstance(value, str):
            yield 1, value


# Characters below U+1F000 that show as emoji by default (Emoji_Presentation).
BMP_EMOJI = [
    (0x231A, 0x231B), (0x23E9, 0x23EC), (0x23F0, 0x23F0), (0x23F3, 0x23F3), (0x25FD, 0x25FE),
    (0x2614, 0x2615), (0x2648, 0x2653), (0x267F, 0x267F), (0x2693, 0x2693), (0x26A1, 0x26A1),
    (0x26AA, 0x26AB), (0x26BD, 0x26BE), (0x26C4, 0x26C5), (0x26CE, 0x26CE), (0x26D4, 0x26D4),
    (0x26EA, 0x26EA), (0x26F2, 0x26F3), (0x26F5, 0x26F5), (0x26FA, 0x26FA), (0x26FD, 0x26FD),
    (0x2705, 0x2705), (0x270A, 0x270B), (0x2728, 0x2728), (0x274C, 0x274C), (0x274E, 0x274E),
    (0x2753, 0x2755), (0x2757, 0x2757), (0x2795, 0x2797), (0x27B0, 0x27B0), (0x27BF, 0x27BF),
    (0x2B1B, 0x2B1C), (0x2B50, 0x2B50), (0x2B55, 0x2B55),
]


def is_emoji(char, following=""):
    code = ord(char)
    return (
        0x1F000 <= code <= 0x1FAFF
        or code in (0xFE0F, 0x20E3, 0x200D)
        or following == "\ufe0f"
        or any(start <= code <= end for start, end in BMP_EMOJI)
    )


def needs_glyph(char):
    if unicodedata.category(char) in ("Cf", "Cc", "Zl", "Zp"):
        return False  # control and format characters draw nothing
    return not is_emoji(char)  # emoji: the system emoji font draws them


def load_cmaps(paths):
    try:
        from fontTools.ttLib import TTFont
    except ImportError:
        print("Needs fontTools: pip install fonttools", file=sys.stderr)
        sys.exit(1)
    cmaps = []
    for path in paths:
        try:
            cmaps.append((Path(path).name, set(TTFont(path, fontNumber=0).getBestCmap())))
        except Exception as error:  # a broken font file is worth a clear message
            print(f"{path}: {error}", file=sys.stderr)
            sys.exit(1)
    return cmaps


def _depths(font, text):
    """(deepest yMin among the glyphs that can draw [text], the char) in font
    units. A character's contextual forms (`.fina`, `.medi`, `.init`) are
    included by glyph name, since a final «ي» is a different glyph."""
    cmap = font.getBestCmap() or {}
    glyf = font["glyf"] if "glyf" in font else None
    glyph_set = font.getGlyphSet()
    names = font.getGlyphOrder()
    deepest, which = 0, None
    for char in text:
        base = cmap.get(ord(char))
        if base is None:
            continue
        variants = [base] + [n for n in names if n.startswith(base + ".")]
        for name in variants:
            if glyf is not None:
                g = glyf[name]
                g.recalcBounds(glyf)
                y_min = getattr(g, "yMin", 0) if g.numberOfContours else 0
            else:
                from fontTools.pens.boundsPen import BoundsPen

                pen = BoundsPen(glyph_set)
                glyph_set[name].draw(pen)
                y_min = pen.bounds[1] if pen.bounds else 0
            if y_min < deepest:
                deepest, which = y_min, char
    return deepest, which


def print_metrics(paths, texts, sizes):
    from fontTools.ttLib import TTFont

    def cm(em, size):
        return em * size * 2.54 / 72

    for path in paths:
        font = TTFont(path, fontNumber=0)
        upem = font["head"].unitsPerEm
        hhea = font["hhea"]
        ascent, descent = hhea.ascent / upem, -hhea.descent / upem
        cmap = font.getBestCmap() or {}
        print(f"{Path(path).name}  (unitsPerEm {upem})")
        print(f"  ascent {ascent:.3f} em, descent {descent:.3f} em (hhea: what the pdf package uses; line box {ascent + descent:.3f} em)")
        if "OS/2" in font:
            os2 = font["OS/2"]
            print(f"  OS/2 typo {os2.sTypoAscender / upem:.3f} / {-os2.sTypoDescender / upem:.3f} em, win {os2.usWinAscent / upem:.3f} / {os2.usWinDescent / upem:.3f} em, fsType {os2.fsType}")
        has_arabic = 0x0627 in cmap
        if has_arabic:
            tatweel = cmap.get(0x0640)
            if tatweel:
                seat, _ = 0, None
                g = font["glyf"][tatweel] if "glyf" in font else None
                if g is not None and g.numberOfContours:
                    g.recalcBounds(font["glyf"])
                    seat = g.yMin / upem
                note = "" if abs(seat) < 0.01 else "  <- Arabic rests above the baseline: lower Arabic text by this much to sit on a printed line"
                print(f"  Arabic rests at {seat:+.3f} em (bottom of «ـ»){note}")
            gsub = font["GSUB"].table if "GSUB" in font else None
            features = {r.FeatureTag for r in gsub.FeatureList.FeatureRecord} if gsub and gsub.FeatureList else set()
            lam_alef = 0xFEFB in cmap or bool(features & {"rlig", "liga"})
            forms = features & {"init", "medi", "fina", "isol"}
            print(f"  Arabic: alef yes, contextual forms {'yes' if forms else 'NO'}, lam-alef {'yes' if lam_alef else 'NO'}")
            gpos = font["GPOS"].table if "GPOS" in font else None
            gpos_features = {r.FeatureTag for r in gpos.FeatureList.FeatureRecord} if gpos and gpos.FeatureList else set()
            if "mark" in gpos_features:
                print("  tashkeel placed by GPOS 'mark': the pdf package doesn't apply it, so «تحريراً» may print with its marks misplaced. Rasterize and look; strip the marks for print if they land wrong")
        else:
            print("  no Arabic letters in this font (Calibri 5.x, for one, has none; 6.x on Windows 10/11 does)")
        for text in texts:
            depth, char = _depths(font, text)
            em = -depth / upem
            sized = "".join(f", {cm(em, size):.3f} cm at {size:g} pt" for size in sizes)
            missing = [c for c in text if c.strip() and ord(c) not in cmap]
            lack = f"  (no glyph for: {''.join(missing)})" if missing else ""
            print(f"  «{text}»: deepest {em:.3f} em below the baseline" + (f" («{char}»)" if char else "") + sized + lack)
        for size in sizes:
            print(f"  at {size:g} pt: ascent {cm(ascent, size):.3f} cm, descent {cm(descent, size):.3f} cm")
        print()


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
    parser = argparse.ArgumentParser(description="Check the fonts cover every character the UI shows.")
    parser.add_argument("paths", nargs="*", help="folders or files to scan (default: lib)")
    parser.add_argument("--font", action="append", required=True, help="the app's font file, one per weight")
    parser.add_argument("--metrics", nargs="*", metavar="TEXT", help="print the fonts' printing metrics (and the deepest glyph of each TEXT) instead of checking coverage")
    parser.add_argument("--size", nargs="*", type=float, default=[], metavar="PT", help="with --metrics: also give the values in cm at these point sizes")
    parser.add_argument("--fallback", action="append", default=[], help="a fontFamilyFallback font file")
    parser.add_argument("--chars", default="", help="characters the app builds at run time, e.g. currency symbols")
    args = parser.parse_args()

    if args.metrics is not None:
        print_metrics(args.font, args.metrics, args.size)
        return 0

    used = {}  # char -> first "file:line"
    files = 0
    for target in args.paths or ["lib"]:
        path = Path(target)
        candidates = sorted(path.rglob("*")) if path.is_dir() else [path]
        for file in candidates:
            if file.suffix == ".dart":
                strings = dart_strings(file.read_text(encoding="utf-8", errors="replace"))
            elif file.suffix == ".arb":
                strings = arb_strings(file)
            else:
                continue
            files += 1
            for line, text in strings:
                for index, char in enumerate(text):
                    following = text[index + 1 : index + 2]
                    if is_emoji(char, following):
                        continue
                    used.setdefault(char, f"{file.as_posix()}:{line}")
    for char in args.chars:
        used.setdefault(char, "--chars")
    # Every printable ASCII character the UI may show (digits, punctuation).
    for code in range(0x20, 0x7F):
        used.setdefault(chr(code), "ASCII")

    fonts, fallbacks = load_cmaps(args.font), load_cmaps(args.fallback)
    missing, fallback_only = [], []
    for char, where in sorted(used.items()):
        if not needs_glyph(char):
            continue
        lacking = [name for name, cmap in fonts if ord(char) not in cmap]
        if not lacking:
            continue
        covered_by = [name for name, cmap in fallbacks if ord(char) in cmap]
        entry = (char, where, lacking, covered_by)
        (fallback_only if covered_by else missing).append(entry)

    print(f"Fonts: {', '.join(name for name, _ in fonts)}" + (f"; fallbacks: {', '.join(name for name, _ in fallbacks)}" if fallbacks else ""))
    print(f"Checked {len(used)} distinct characters from {files} file(s){' and --chars' if args.chars else ''}.")
    for title, entries in (("Missing (box or a different system font):", missing), ("Only in a fallback (check it looks right):", fallback_only)):
        if not entries:
            continue
        print(f"\n{title}")
        for char, where, lacking, covered_by in entries:
            name = unicodedata.name(char, "?")
            via = f" -> {', '.join(covered_by)}" if covered_by else ""
            print(f"  U+{ord(char):04X} {char}  {name.lower()}  ({where}; not in {', '.join(lacking)}){via}")
    if missing:
        print("\nFix: a font that has them, or add one to fontFamilyFallback (and to the PDF theme if documents print them).")
        return 2
    print("\nEvery character is covered." if not fallback_only else "")
    return 0


if __name__ == "__main__":
    sys.exit(main())

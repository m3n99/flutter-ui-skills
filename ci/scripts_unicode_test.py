#!/usr/bin/env python3
"""CI only, run on Windows too: the scripts print Arabic without crashing
when the console isn't UTF-8. A Windows console or pipe defaults to the
ANSI code page (cp1252), where print() of Arabic raises UnicodeEncodeError
and subprocess output with Arabic fails to decode.

    python3 ci/scripts_unicode_test.py <font.ttf>

Needs PyMuPDF and fontTools.
"""

import os
import subprocess
import sys
import tempfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "plugins/flutter-modern-ui/skills"
RASTERIZE = SKILLS / "flutter-ui-verify/scripts/rasterize_pdf.py"
MEASURE = SKILLS / "flutter-ui-verify/scripts/measure_pdf.py"
GLYPHS = SKILLS / "flutter-ui-verify/scripts/check_glyphs.py"
PALETTE = SKILLS / "flutter-modern-ui/scripts/palette.py"

# The console as Windows has it: no UTF-8 mode, no forced IO encoding.
ENV = {k: v for k, v in os.environ.items() if k not in ("PYTHONIOENCODING", "PYTHONUTF8")}
ENV["PYTHONUTF8"] = "0"


def run(*args):
    result = subprocess.run([sys.executable, *map(str, args)], capture_output=True, env=ENV)
    return result.returncode, result.stdout.decode("utf-8", "replace"), result.stderr.decode("utf-8", "replace")


def main():
    font = Path(sys.argv[1])
    try:
        import pymupdf as fitz
    except ImportError:
        import fitz

    failures = []
    print(f"stdout encoding here: {sys.stdout.encoding}")
    with tempfile.TemporaryDirectory() as folder:
        out = Path(folder)
        cm = 72 / 2.54
        for name in ("a", "b"):
            document = fitz.open()
            page = document.new_page(width=15 * cm, height=8 * cm)
            writer = fitz.TextWriter(page.rect)
            writer.append((2 * cm, 3.6 * cm), "تحريراً في 12/11/2026", font=fitz.Font(fontfile=str(font)), fontsize=13)
            writer.write_text(page)
            document.save(out / f"cheque_{name}.pdf")

        code, stdout, stderr = run(RASTERIZE, out, "--text")
        pngs = sorted(out.glob("*.png"))
        if code != 0 or len(pngs) != 2:
            failures.append(f"rasterize_pdf.py --text: exit {code}, {len(pngs)} PNG(s) of 2\n{stderr[-400:]}")

        code, stdout, stderr = run(MEASURE, out / "cheque_a.pdf", "--window", "date", 1.5, 2.9, 14, 4.0)
        if code != 0 or "baseline" not in stdout:
            failures.append(f"measure_pdf.py --window: exit {code}\n{stderr[-400:]}")

        code, stdout, stderr = run(GLYPHS, "--font", font, "--metrics", "تحريراً في", "--size", 11)
        if code != 0 or "«تحريراً في»" not in stdout:
            failures.append(f"check_glyphs.py --metrics with Arabic: exit {code}\n{stderr[-400:]}")

        code, stdout, stderr = run(PALETTE, "--curated", "arabic")
        if code != 0 or "Tatreez" not in stdout:
            failures.append(f"palette.py --curated: exit {code}\n{stderr[-400:]}")

    for failure in failures:
        print(f"FAIL {failure}")
    print("passed" if not failures else f"{len(failures)} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

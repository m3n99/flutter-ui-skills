#!/usr/bin/env python3
"""Measure where text was printed on a PDF page, in centimeters.

For documents whose values must land on fixed spots: a cheque, a bank slip,
a government form (references/preprinted-forms.md). Looking at a PNG can't
tell 7.6 cm from 7.9 cm; this can.

    # Ad hoc: the ink in a window (x0 y0 x1 y1 in cm from the page's top-left corner)
    python3 measure_pdf.py docs/samples/cheque.pdf --window payee 2.0 2.6 15.0 3.7

    # Checked: every *.measure.json next to the PDFs (written by the PDF test)
    python3 measure_pdf.py test/pdf/out

For each window it reports the ink's bounding box and the **baseline**: the
bottom of the densest band of ink, which is where the letters sit. Arabic
tails («ي ع ر و ن») and «/» go below it, so the ink box's bottom is not the
baseline; measure the baseline. Ink is anything darker than --threshold
(default 110 of 255), so light grey guide lines drawn for a preview are
ignored.

A *.measure.json file:

    {"pdf": "cheque_typical.pdf", "page": 1,
     "fields": [{"name": "payee", "window": [2.0, 2.6, 15.0, 3.7],
                 "anchor": "right", "baseline": 3.30, "start": 14.40,
                 "end_limit": 2.20,
                 "tolerance": {"baseline": 0.05, "start_past": 0.14, "start_short": 0.08}}]}

checks, per field: the baseline is within tolerance of `baseline`; the ink
starts at `start` (the right edge with "anchor": "right", for Arabic or an
amount anchored away from a label; the left otherwise), no further past it
than `start_past` (the pdf package draws some Arabic beyond the width it
measured) and no further short of it than `start_short`; and no ink passes
`end_limit`. `"expect": "fail"` marks a sample that is meant to fail (a
test of the check itself), `"expect": "report"` one that is only measured.
The PDF test writes these files from the document's layout constants
(`writePdfWithMeasures` in the PDF harness). Needs PyMuPDF: pip install pymupdf.
Exit codes: 0 all checks pass, 1 a check failed, 2 an error.
"""

import argparse
import json
import sys
from pathlib import Path

PT_PER_CM = 72 / 2.54


def utf8_console():
    """Arabic in the output must not stop the script: a Windows console or
    pipe defaults to the ANSI code page (cp1252), where print() of Arabic
    raises UnicodeEncodeError."""
    for stream in (sys.stdout, sys.stderr):
        try:
            stream.reconfigure(encoding="utf-8", errors="replace")
        except (AttributeError, ValueError):
            pass


def measure(page, window, dpi, threshold, band=0.35):
    """The ink in [window] (cm, from the top-left corner): None when empty,
    else a dict with left, right, top, bottom and baseline in cm."""
    fitz = _fitz()

    x0, y0, x1, y1 = window
    clip = fitz.Rect(x0 * PT_PER_CM, y0 * PT_PER_CM, x1 * PT_PER_CM, y1 * PT_PER_CM)
    pix = page.get_pixmap(dpi=dpi, clip=clip, colorspace=fitz.csGRAY, alpha=False)
    w, h, data, stride = pix.width, pix.height, pix.samples, pix.stride
    cols = [0] * w
    rows = [0] * h
    for y in range(h):
        row = data[y * stride : y * stride + w]
        count = 0
        for x, value in enumerate(row):
            if value < threshold:
                cols[x] += 1
                count += 1
        rows[y] = count
    if not any(rows):
        return None
    cm_per_px_x = (x1 - x0) / w
    cm_per_px_y = (y1 - y0) / h
    xs = [x for x, c in enumerate(cols) if c]
    ys = [y for y, c in enumerate(rows) if c]
    peak = max(rows)
    dense = [y for y, c in enumerate(rows) if c >= band * peak]
    return {
        "left": x0 + xs[0] * cm_per_px_x,
        "right": x0 + (xs[-1] + 1) * cm_per_px_x,
        "top": y0 + ys[0] * cm_per_px_y,
        "bottom": y0 + (ys[-1] + 1) * cm_per_px_y,
        "baseline": y0 + (dense[-1] + 1) * cm_per_px_y,
    }


def check(field, ink):
    """Problems with one measured field (empty when it's where it should be)."""
    if ink is None:
        return ["no ink in the window: the value wasn't printed, or printed elsewhere"]
    tol = {"baseline": 0.05, "start": 0.08, **field.get("tolerance", {})}
    past_tol = tol.get("start_past", tol["start"])
    short_tol = tol.get("start_short", tol["start"])
    problems = []
    if "baseline" in field:
        off = ink["baseline"] - field["baseline"]
        if abs(off) > tol["baseline"]:
            way = "below" if off > 0 else "above"
            problems.append(f"baseline {ink['baseline']:.3f} cm, {abs(off):.3f} cm {way} its line at {field['baseline']:.2f}")
    right = field.get("anchor", "right" if field.get("direction") == "rtl" else "left") == "right"
    if "start" in field:
        edge = ink["right"] if right else ink["left"]
        past = (edge - field["start"]) if right else (field["start"] - edge)
        if past > past_tol:
            problems.append(f"starts at {edge:.3f} cm, {past:.3f} cm past its start {field['start']:.2f}")
        elif -past > short_tol:
            problems.append(
                f"starts at {edge:.3f} cm, {-past:.3f} cm short of its start {field['start']:.2f}: "
                "a first letter clipped (a FittedBox with no start margin), or text placed wrong"
            )
    if "end_limit" in field:
        edge = ink["left"] if right else ink["right"]
        over = (field["end_limit"] - edge) if right else (edge - field["end_limit"])
        if over > 0.005:
            problems.append(f"ink reaches {edge:.3f} cm, {over:.3f} cm past its end {field['end_limit']:.2f}")
    return problems


def _fitz():
    try:
        import pymupdf as fitz
    except ImportError:
        import fitz
    return fitz


def run_spec(spec_path, dpi, threshold):
    fitz = _fitz()

    spec = json.loads(spec_path.read_text(encoding="utf-8"))
    pdf = spec_path.parent / spec["pdf"]
    failures = 0
    with fitz.open(pdf) as document:
        page = document[spec.get("page", 1) - 1]
        size = f"{page.rect.width / PT_PER_CM:.2f} × {page.rect.height / PT_PER_CM:.2f} cm"
        print(f"{pdf.name} page {spec.get('page', 1)} ({size}):")
        for field in spec["fields"]:
            ink = measure(page, field["window"], dpi, threshold)
            problems = check(field, ink)
            expect = field.get("expect", "pass")
            expect_fail = expect == "fail"
            where = "" if ink is None else (
                f"ink {ink['left']:.2f}–{ink['right']:.2f} × {ink['top']:.2f}–{ink['bottom']:.2f} cm, baseline {ink['baseline']:.3f}"
            )
            if expect == "report":
                ok, status = True, "report"
            elif expect_fail:
                ok = bool(problems)
                status = "ok (fails as it should)" if ok else "FAIL: was meant to fail and didn't"
            else:
                ok = not problems
                status = "ok" if ok else "FAIL"
            print(f"  {status:<8} {field['name']}: {where}")
            for problem in problems:
                print(f"           {problem}")
            failures += 0 if ok else 1
    return failures


def main():
    utf8_console()
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("paths", nargs="+", help="a PDF (with --window) or *.measure.json files / folders holding them")
    parser.add_argument("--window", nargs=5, action="append", metavar=("NAME", "X0", "Y0", "X1", "Y1"), help="measure the ink in this window (cm from the top-left corner)")
    parser.add_argument("--page", type=int, default=1)
    parser.add_argument("--dpi", type=int, default=600, help="raster resolution (600: 0.004 cm per pixel)")
    parser.add_argument("--threshold", type=int, default=110, help="ink is darker than this (0-255); grey guides stay out")
    args = parser.parse_args()

    try:
        fitz = _fitz()
    except ImportError:
        print("Needs PyMuPDF: pip install pymupdf", file=sys.stderr)
        return 2

    if args.window:
        with fitz.open(args.paths[0]) as document:
            page = document[args.page - 1]
            print(f"{Path(args.paths[0]).name} page {args.page}: {page.rect.width / PT_PER_CM:.2f} × {page.rect.height / PT_PER_CM:.2f} cm")
            for name, *box in args.window:
                ink = measure(page, [float(v) for v in box], args.dpi, args.threshold)
                if ink is None:
                    print(f"  {name}: no ink")
                else:
                    print(
                        f"  {name}: ink x {ink['left']:.3f}–{ink['right']:.3f} cm, y {ink['top']:.3f}–{ink['bottom']:.3f} cm, "
                        f"baseline {ink['baseline']:.3f} cm"
                    )
        return 0

    specs = []
    for target in args.paths:
        path = Path(target)
        specs += sorted(path.rglob("*.measure.json")) if path.is_dir() else [path]
    if not specs:
        print("No *.measure.json files found.", file=sys.stderr)
        return 2
    failures = sum(run_spec(spec, args.dpi, args.threshold) for spec in specs)
    print(f"\n{failures} field(s) off." if failures else "\nEvery field is where it should be.")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

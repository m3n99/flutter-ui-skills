#!/usr/bin/env python3
"""Rasterize PDF pages to PNG so they can be opened and reviewed.

    python3 rasterize_pdf.py test/pdf/out                  # every PDF in a folder
    python3 rasterize_pdf.py a.pdf b.pdf --dpi 200 --pages 1,3-4
    python3 rasterize_pdf.py test/pdf/out --text           # also check the text

Writes <name>_p<N>.png next to each PDF and prints the paths. Uses PyMuPDF
(`pip install pymupdf`) when it is installed, otherwise poppler's pdftoppm
and pdftotext. `Printing.raster` from the printing package needs the pdfium
library, which `flutter test` doesn't load, so rasterize outside the test run.

--text prints each page's text and flags what empty optional fields tend to
leave behind: "null", "NaN", "Infinity", "undefined", "Instance of".

Exit codes: 0 fine, 1 error, 2 leftovers found (with --text).
"""

import argparse
import re
import shutil
import subprocess
import sys
from pathlib import Path

LEFTOVERS = re.compile(r"\b(?:null|NaN|Infinity|undefined)\b|Instance of")


def load_pymupdf():
    try:
        import pymupdf  # PyMuPDF >= 1.24
        return pymupdf
    except ImportError:
        pass
    try:
        import fitz  # older PyMuPDF
        return fitz
    except ImportError:
        return None


def find_pdfs(paths):
    pdfs = []
    for raw in paths:
        path = Path(raw)
        if path.is_dir():
            pdfs.extend(sorted(path.glob("*.pdf")))
        elif path.is_file() and path.suffix.lower() == ".pdf":
            pdfs.append(path)
        else:
            print(f"skipped, not a PDF or a folder: {path}", file=sys.stderr)
    return pdfs


def parse_pages(spec, count):
    if not spec:
        return list(range(1, count + 1))
    pages = set()
    for part in spec.split(","):
        part = part.strip()
        if "-" in part:
            start, end = part.split("-", 1)
            pages.update(range(int(start), int(end) + 1))
        elif part:
            pages.add(int(part))
    return [page for page in sorted(pages) if 1 <= page <= count]


def png_path(pdf, number):
    return pdf.with_name(f"{pdf.stem}_p{number}.png")


def render_pymupdf(module, pdf, pages, dpi, want_text):
    pngs, texts = [], {}
    with module.open(pdf) as document:
        for number in parse_pages(pages, document.page_count):
            page = document[number - 1]
            png = png_path(pdf, number)
            page.get_pixmap(dpi=dpi).save(png)
            pngs.append(png)
            if want_text:
                texts[number] = page.get_text()
    return pngs, texts


def render_poppler(pdf, pages, dpi, want_text):
    info = subprocess.run(["pdfinfo", str(pdf)], capture_output=True, text=True, check=True).stdout
    match = re.search(r"^Pages:\s+(\d+)", info, re.MULTILINE)
    count = int(match.group(1)) if match else 1
    pngs, texts = [], {}
    for number in parse_pages(pages, count):
        png = png_path(pdf, number)
        first_last = ["-f", str(number), "-l", str(number)]
        subprocess.run(
            ["pdftoppm", "-png", "-r", str(dpi), *first_last, "-singlefile", str(pdf), str(png.with_suffix(""))],
            check=True,
        )
        pngs.append(png)
        if want_text:
            texts[number] = subprocess.run(
                ["pdftotext", "-layout", *first_last, str(pdf), "-"], capture_output=True, text=True, check=True
            ).stdout
    return pngs, texts


def main():
    parser = argparse.ArgumentParser(description="Rasterize PDF pages to PNG for review.")
    parser.add_argument("paths", nargs="+", help="PDF files or folders of PDFs")
    parser.add_argument("--dpi", type=int, default=150, help="resolution (default 150)")
    parser.add_argument("--pages", help="pages to render, e.g. 1 or 1,3-4 (default: all)")
    parser.add_argument("--text", action="store_true", help="print each page's text and flag leftovers such as null")
    parser.add_argument("--engine", choices=["auto", "pymupdf", "poppler"], default="auto")
    args = parser.parse_args()

    pdfs = find_pdfs(args.paths)
    if not pdfs:
        print("No PDFs found.", file=sys.stderr)
        return 1

    module = load_pymupdf() if args.engine in ("auto", "pymupdf") else None
    has_poppler = shutil.which("pdftoppm") is not None and shutil.which("pdfinfo") is not None
    if module is None and (args.engine == "pymupdf" or not has_poppler):
        print("Needs PyMuPDF (pip install pymupdf) or poppler (pdftoppm, pdfinfo, pdftotext).", file=sys.stderr)
        return 1

    flagged = errors = 0
    for pdf in pdfs:
        try:
            if module is not None:
                pngs, texts = render_pymupdf(module, pdf, args.pages, args.dpi, args.text)
            else:
                pngs, texts = render_poppler(pdf, args.pages, args.dpi, args.text)
        except Exception as error:  # a broken PDF shouldn't hide the others
            print(f"{pdf}: {error}", file=sys.stderr)
            errors += 1
            continue
        for png in pngs:
            print(png)
        for number, text in texts.items():
            print(f"--- {pdf.name} · page {number} ---")
            print(text.strip())
            found = sorted({match.group(0) for match in LEFTOVERS.finditer(text)})
            if found:
                flagged += 1
                print(f"!!! {pdf.name} page {number}: {', '.join(found)} printed (an empty optional field?)")
    if errors:
        return 1
    return 2 if flagged else 0


if __name__ == "__main__":
    sys.exit(main())

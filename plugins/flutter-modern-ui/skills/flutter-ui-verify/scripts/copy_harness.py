#!/usr/bin/env python3
"""Copy the UI test harness (and optionally the PDF harness) into a project.

    python3 copy_harness.py                          # test/ui
    python3 copy_harness.py --pdf                    # also test/pdf (needs the pdf package)
    python3 copy_harness.py --design-system-test     # also the shared-widget tests
    python3 copy_harness.py --to test/visual --pdf test/print

The project-independent files are copied over existing ones, so running it
again updates them. The files you edit (ui_cases.dart, pdf_cases.dart) are
only copied when missing; then replace their `package:app/...` imports and
cases with the project's own.

When pubspec.yaml depends on material_ui (Flutter 3.50+), Material and
Cupertino imports are rewritten to package:material_ui / package:cupertino_ui.

Exit codes: 0 fine, 1 error.
"""

import argparse
import re
import shutil
import sys
from pathlib import Path

ASSETS = Path(__file__).resolve().parent.parent / "assets"

UI_FILES = ["ui_harness.dart", "layout_smoke_test.dart", "sheets_test.dart", "contrast_test.dart", "visual_test.dart"]
UI_EDITED = "ui_cases.dart"
DESIGN_SYSTEM_TEST = "design_system_test.dart"
PDF_FILES = ["pdf_harness.dart", "pdf_test.dart"]
PDF_EDITED = "pdf_cases.dart"

IMPORT_REWRITES = {
    "package:flutter/material.dart": "package:material_ui/material_ui.dart",
    "package:flutter/cupertino.dart": "package:cupertino_ui/cupertino_ui.dart",
}


def find_pubspec(start):
    for folder in [start, *start.parents]:
        if (folder / "pubspec.yaml").is_file():
            return folder / "pubspec.yaml"
    return None


def dependencies(pubspec):
    names, section = set(), None
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if re.match(r"^\S", line):
            section = line.split(":")[0].strip()
            continue
        match = re.match(r"^  ([a-z0-9_]+)\s*:", line)
        if match and section in ("dependencies", "dev_dependencies"):
            names.add(match.group(1))
    return names


def copy(source_dir, target, names, edited, force_edited=False):
    target.mkdir(parents=True, exist_ok=True)
    written, skipped = [], []
    for name in names:
        shutil.copyfile(source_dir / name, target / name)
        written.append(target / name)
    if edited:
        dest = target / edited
        if dest.exists() and not force_edited:
            skipped.append(dest)
        else:
            shutil.copyfile(source_dir / edited, dest)
            written.append(dest)
    return written, skipped


def adapt_imports(files, deps):
    if "material_ui" not in deps:
        return []
    changed = []
    for path in files:
        text = path.read_text(encoding="utf-8")
        new = text
        for old, replacement in IMPORT_REWRITES.items():
            new = new.replace(f"'{old}'", f"'{replacement}'")
        if new != text:
            path.write_text(new, encoding="utf-8")
            changed.append(path)
    return changed


def main():
    parser = argparse.ArgumentParser(description="Copy the flutter-ui-verify harness into a Flutter project.")
    parser.add_argument("--to", default="test/ui", help="UI harness folder (default test/ui)")
    parser.add_argument("--pdf", nargs="?", const="test/pdf", help="also copy the PDF harness (default folder test/pdf)")
    parser.add_argument("--design-system-test", action="store_true", help="also copy the shared-widget tests")
    parser.add_argument("--force-cases", action="store_true", help="overwrite ui_cases.dart / pdf_cases.dart too")
    args = parser.parse_args()

    target = Path(args.to)
    pubspec = find_pubspec(target.resolve())
    if pubspec is None:
        print("No pubspec.yaml found. Run it from the Flutter project.", file=sys.stderr)
        return 1
    deps = dependencies(pubspec)

    names = UI_FILES + ([DESIGN_SYSTEM_TEST] if args.design_system_test else [])
    written, skipped = copy(ASSETS / "harness", target, names, UI_EDITED, args.force_cases)
    if args.pdf:
        pdf_written, pdf_skipped = copy(ASSETS / "pdf", Path(args.pdf), PDF_FILES, PDF_EDITED, args.force_cases)
        written += pdf_written
        skipped += pdf_skipped

    changed = adapt_imports(written, deps)
    print(f"Wrote {len(written)} file(s).")
    for path in skipped:
        print(f"Kept your {path} (--force-cases overwrites it).")
    if changed:
        print(f"Imports rewritten for material_ui in {len(changed)} file(s).")
    if args.pdf and "pdf" not in deps:
        print("The PDF harness needs the pdf package: flutter pub add pdf")
    if any(path.name in (UI_EDITED, PDF_EDITED) for path in written):
        print("Next: edit the *_cases.dart files: imports, theme, screens in every state, forms in create and edit mode, the shell, sheets.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

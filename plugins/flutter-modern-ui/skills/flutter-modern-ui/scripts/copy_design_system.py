#!/usr/bin/env python3
"""Copy the design-system templates into a Flutter project, kit by kit.

    python3 copy_design_system.py                          # core kit -> lib/core/design_system
    python3 copy_design_system.py --kit extras             # add motion, adaptive shell, KPI tiles
    python3 copy_design_system.py --kit all --to lib/ui/design_system
    python3 copy_design_system.py --adapt lib/examples     # only fix imports in copied code
    python3 copy_design_system.py --list

Kits
  core    tokens, density, palette, typography, theme, context extensions,
          AppCard, PressScale, StatusPill / IconBadge / EmojiBadge, EmptyState,
          skeletons, sheets and pickers, chips, messages, SectionHeader, Ltr.
          What every app needs; enough for an Android-only app.
  extras  motion (Entrance, AnimatedItems, StateSwitcher, ShakeOnChange,
          SubmitButton, AnimatedNumber, AppProgressBar, MiniBarChart),
          AdaptiveShell / ContentWidth, KpiTile / KpiGrid. Add when the app
          animates, ships on tablets or desktop, or has a dashboard.
  all     both.

Existing files are kept (your edits win) unless --force. The barrel
(design_system.dart) is rewritten to export every kit file in the folder;
lines below its "your exports" marker are kept.

Flutter 3.50 deprecates package:flutter/material.dart in favour of the
material_ui package. When the project's pubspec.yaml depends on material_ui,
the copied files import package:material_ui/material_ui.dart and
package:cupertino_ui/cupertino_ui.dart instead (same as
`dart fix --apply --code=migrate_design_widgets`).

Exit codes: 0 fine, 1 error.
"""

import argparse
import re
import shutil
import sys
from pathlib import Path

TEMPLATES = Path(__file__).resolve().parent.parent / "assets" / "design_system"

KITS = {
    "core": [
        "tokens.dart",
        "app_density.dart",
        "app_palette.dart",
        "app_typography.dart",
        "app_theme.dart",
        "context_ext.dart",
        "widgets/app_card.dart",
        "widgets/press_scale.dart",
        "widgets/status_pill.dart",
        "widgets/empty_state.dart",
        "widgets/skeleton.dart",
        "widgets/app_sheet.dart",
        "widgets/controls.dart",
        "widgets/app_messenger.dart",
        "widgets/section_header.dart",
        "widgets/ltr.dart",
    ],
    "extras": [
        "motion/entrance.dart",
        "motion/animated_items.dart",
        "motion/micro_interactions.dart",
        "motion/submit_button.dart",
        "motion/value_motion.dart",
        "motion/mini_bar_chart.dart",
        "widgets/adaptive_shell.dart",
        "widgets/kpi_tile.dart",
    ],
}
KITS["all"] = KITS["core"] + KITS["extras"]

BARREL = "design_system.dart"
MARKER = "// --- your exports below this line are kept ---"

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
    """Package names under `dependencies:` and `dev_dependencies:`."""
    names, section = set(), None
    for line in pubspec.read_text(encoding="utf-8").splitlines():
        if re.match(r"^\S", line):
            section = line.split(":")[0].strip()
            continue
        match = re.match(r"^  ([a-z0-9_]+)\s*:", line)
        if match and section in ("dependencies", "dev_dependencies"):
            names.add(match.group(1))
    return names


def adapt_imports(files, deps):
    """Rewrite framework Material/Cupertino imports when the project uses
    material_ui. Returns the files changed and whether cupertino_ui is needed."""
    if "material_ui" not in deps:
        return [], False
    changed, needs_cupertino = [], False
    for path in files:
        text = path.read_text(encoding="utf-8")
        new = text
        for old, replacement in IMPORT_REWRITES.items():
            new = new.replace(f"'{old}'", f"'{replacement}'").replace(f'"{old}"', f'"{replacement}"')
        if "package:cupertino_ui/" in new:
            needs_cupertino = True
        if new != text:
            path.write_text(new, encoding="utf-8")
            changed.append(path)
    return changed, needs_cupertino


def write_barrel(target):
    present = [rel for rel in KITS["all"] if (target / rel).is_file()]
    barrel = target / BARREL
    kept = []
    if barrel.is_file():
        lines = barrel.read_text(encoding="utf-8").splitlines()
        if MARKER in lines:
            kept = lines[lines.index(MARKER) + 1 :]
    header = [
        "/// Barrel file: `import 'package:<app>/<path>/design_system.dart';`",
        "/// Written by copy_design_system.py from the kit files in this folder.",
        "library;",
        "",
    ]
    body = [f"export '{rel}';" for rel in sorted(present)]
    barrel.write_text("\n".join(header + body + ["", MARKER, *kept]).rstrip("\n") + "\n", encoding="utf-8")
    return present


def main():
    parser = argparse.ArgumentParser(description="Copy design-system templates into a Flutter project.")
    parser.add_argument("--kit", choices=sorted(KITS), default="core")
    parser.add_argument("--to", default="lib/core/design_system", help="target folder (default lib/core/design_system)")
    parser.add_argument("--force", action="store_true", help="overwrite files that already exist")
    parser.add_argument("--adapt", nargs="+", metavar="DIR", help="only rewrite imports in these folders")
    parser.add_argument("--list", action="store_true", help="list the kits and exit")
    args = parser.parse_args()

    if args.list:
        for kit in ("core", "extras"):
            print(f"{kit}:")
            for rel in KITS[kit]:
                print(f"  {rel}")
        return 0

    start = Path(args.adapt[0] if args.adapt else args.to).resolve()
    pubspec = find_pubspec(start if start.exists() else start.parent)
    if pubspec is None:
        print(f"No pubspec.yaml at or above {start}. Run it from the Flutter project.", file=sys.stderr)
        return 1
    deps = dependencies(pubspec)

    if args.adapt:
        files = [f for folder in args.adapt for f in sorted(Path(folder).rglob("*.dart"))]
        changed, needs_cupertino = adapt_imports(files, deps)
        print(f"Imports rewritten for material_ui in {len(changed)} file(s)." if changed else "No imports to rewrite.")
        if needs_cupertino and "cupertino_ui" not in deps:
            print("Add the Cupertino package too: flutter pub add cupertino_ui")
        return 0

    target = Path(args.to)
    copied, kept = [], []
    for rel in KITS[args.kit]:
        source, dest = TEMPLATES / rel, target / rel
        if dest.exists() and not args.force:
            kept.append(rel)
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        shutil.copyfile(source, dest)
        copied.append(dest)

    changed, needs_cupertino = adapt_imports(copied, deps)
    present = write_barrel(target)

    print(f"Copied {len(copied)} file(s) of the {args.kit} kit to {target}.")
    if kept:
        print(f"Kept {len(kept)} existing file(s) (--force overwrites): {', '.join(kept)}")
    print(f"{BARREL} exports {len(present)} file(s).")
    if changed:
        print(f"Imports rewritten for material_ui in {len(changed)} file(s).")
    if needs_cupertino and "cupertino_ui" not in deps:
        print("app_theme.dart needs CupertinoPageTransitionsBuilder: flutter pub add cupertino_ui")
    print("Next: set AppTheme.config (seed, variant, font, script), wire AppTheme.light/dark and AppMessenger.key in MaterialApp, write DESIGN.md.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

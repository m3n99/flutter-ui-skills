#!/usr/bin/env python3
"""Copy the design-system templates into a Flutter project, kit by kit.

    python3 copy_design_system.py                          # core kit -> lib/core/design_system
    python3 copy_design_system.py --kit extras             # add motion, adaptive shell, KPI tiles
    python3 copy_design_system.py --kit all --to lib/ui/design_system
    python3 copy_design_system.py --adapt lib/examples     # only fix imports in copied code
    python3 copy_design_system.py --list
    python3 copy_design_system.py --status                 # what changed since you copied
    python3 copy_design_system.py --diff widgets/app_card.dart
    python3 copy_design_system.py --update                 # take template fixes you haven't edited over

Kits
  core    tokens, density, motion level, palette, typography, theme, context
          extensions, AppCard, PressScale, StatusPill / IconBadge / EmojiBadge,
          MetaItem, EmptyState, skeletons, sheets and pickers, chips, SaveBar,
          messages, SectionHeader, Ltr. What every app needs; enough for an
          Android-only app.
  extras  motion (Entrance, AnimatedItems, StateSwitcher, ShakeOnChange,
          SubmitButton, AnimatedNumber, AppProgressBar, MiniBarChart),
          AdaptiveShell / ContentWidth, KpiTile / KpiGrid. Add when the app
          animates, ships on tablets or desktop, or has a dashboard.
  all     both.

Existing files are kept (your edits win) unless --force. The barrel
(design_system.dart) is rewritten to export every kit file in the folder;
lines below its "your exports" marker are kept.

Updates. The copy is yours to edit, so the plugin never overwrites it
silently. Each copy records the plugin version and a hash of every file it
wrote in `.flutter-modern-ui.json` next to them (commit it). From that:
  --status  lists each file as up to date, edited by you, changed in the
            plugin since you copied it, or both;
  --update  overwrites only the files the plugin changed and you did not
            edit, and names the ones that need a look;
  --diff    prints your file against the current template (all files that
            differ, or the ones you name).
A folder copied before 1.5 has no record: --status then only says which
files differ from the current templates, and --diff shows how.

Flutter 3.50 deprecates package:flutter/material.dart in favour of the
material_ui package. When the project's pubspec.yaml depends on material_ui,
the copied files import package:material_ui/material_ui.dart and
package:cupertino_ui/cupertino_ui.dart instead (same as
`dart fix --apply --code=migrate_design_widgets`).

Exit codes: 0 fine, 1 error.
"""

import argparse
import difflib
import hashlib
import json
import re
import sys
from pathlib import Path

TEMPLATES = Path(__file__).resolve().parent.parent / "assets" / "design_system"

KITS = {
    "core": [
        "tokens.dart",
        "app_density.dart",
        "app_motion.dart",
        "app_palette.dart",
        "app_typography.dart",
        "app_theme.dart",
        "context_ext.dart",
        "widgets/app_card.dart",
        "widgets/press_scale.dart",
        "widgets/status_pill.dart",
        "widgets/meta_item.dart",
        "widgets/empty_state.dart",
        "widgets/skeleton.dart",
        "widgets/app_sheet.dart",
        "widgets/controls.dart",
        "widgets/save_bar.dart",
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

PLUGIN_JSON = Path(__file__).resolve().parents[3] / ".claude-plugin" / "plugin.json"
STAMP = ".flutter-modern-ui.json"

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


def plugin_version():
    try:
        return json.loads(PLUGIN_JSON.read_text(encoding="utf-8"))["version"]
    except (OSError, ValueError, KeyError):
        return "unknown"


def adapt_text(text, deps):
    """[text] with framework Material/Cupertino imports rewritten when the
    project uses material_ui."""
    if "material_ui" not in deps:
        return text
    for old, replacement in IMPORT_REWRITES.items():
        text = text.replace(f"'{old}'", f"'{replacement}'").replace(f'"{old}"', f'"{replacement}"')
    return text


def adapt_imports(files, deps):
    """Rewrite imports in copied code (--adapt). Returns the files changed and
    whether cupertino_ui is needed."""
    changed, needs_cupertino = [], False
    for path in files:
        text = path.read_text(encoding="utf-8")
        new = adapt_text(text, deps)
        if "package:cupertino_ui/" in new:
            needs_cupertino = True
        if new != text:
            path.write_text(new, encoding="utf-8")
            changed.append(path)
    return changed, needs_cupertino


def template_text(rel, deps):
    """The current template as it would be written into this project."""
    return adapt_text((TEMPLATES / rel).read_text(encoding="utf-8"), deps)


def digest(text):
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def read_stamp(target):
    try:
        data = json.loads((target / STAMP).read_text(encoding="utf-8"))
        return data if isinstance(data.get("files"), dict) else {"files": {}}
    except (OSError, ValueError):
        return {"files": {}}


def write_stamp(target, stamp):
    stamp["plugin"] = "flutter-modern-ui"
    stamp["version"] = plugin_version()
    stamp["files"] = dict(sorted(stamp["files"].items()))
    (target / STAMP).write_text(json.dumps(stamp, indent=2) + "\n", encoding="utf-8")


def file_states(target, deps):
    """(rel, state, copied_version) for every kit file in [target]. States:
    current, update (the plugin changed it, you didn't), edited (you changed
    it, the plugin didn't), both, unknown (differs, no record)."""
    recorded = read_stamp(target)["files"]
    states = []
    for rel in KITS["all"]:
        local = target / rel
        if not local.is_file():
            continue
        mine = digest(local.read_text(encoding="utf-8"))
        current = digest(template_text(rel, deps))
        entry = recorded.get(rel)
        copied = entry.get("sha256") if isinstance(entry, dict) else None
        version = entry.get("version") if isinstance(entry, dict) else None
        if mine == current:
            state = "current"
        elif copied is None:
            state = "unknown"
        elif mine == copied:
            state = "update"
        elif copied == current:
            state = "edited"
        else:
            state = "both"
        states.append((rel, state, version))
    return states


def print_status(target, deps):
    states = file_states(target, deps)
    if not states:
        print(f"No design-system files in {target}.")
        return
    labels = {
        "current": "up to date",
        "update": "changed in the plugin since you copied it (--update takes it)",
        "edited": "edited by you; the template hasn't changed",
        "both": "edited by you and changed in the plugin (--diff shows both)",
        "unknown": "differs from the current template; no record of what was copied (--diff shows how)",
    }
    print(f"{target} against flutter-modern-ui {plugin_version()}:")
    for rel, state, version in states:
        since = f", copied from {version}" if version and state != "current" else ""
        print(f"  {rel}: {labels[state]}{since}")
    missing = [rel for rel in KITS["all"] if not (target / rel).is_file()]
    if missing:
        print(f"Not copied ({len(missing)}): {', '.join(missing)}")


def print_diff(target, deps, names):
    rels = names or [rel for rel, state, _ in file_states(target, deps) if state != "current"]
    shown = 0
    for rel in rels:
        local = target / rel
        if rel not in KITS["all"] or not local.is_file():
            print(f"{rel}: not a kit file in {target}", file=sys.stderr)
            continue
        diff = list(
            difflib.unified_diff(
                local.read_text(encoding="utf-8").splitlines(keepends=True),
                template_text(rel, deps).splitlines(keepends=True),
                fromfile=f"yours/{rel}",
                tofile=f"flutter-modern-ui {plugin_version()}/{rel}",
            )
        )
        if diff:
            sys.stdout.writelines(diff)
            shown += 1
    if not shown:
        print("No differences from the current templates.")


def update(target, deps):
    stamp = read_stamp(target)
    version = plugin_version()
    updated, review = [], []
    for rel, state, _ in file_states(target, deps):
        text = template_text(rel, deps)
        if state == "update":
            (target / rel).write_text(text, encoding="utf-8")
            updated.append(rel)
        elif state in ("both", "unknown"):
            review.append(rel)
            continue
        elif state == "edited":
            continue
        stamp["files"][rel] = {"version": version, "sha256": digest(text)}
    write_stamp(target, stamp)
    write_barrel(target)
    print(f"Updated {len(updated)} file(s) to {version}" + (f": {', '.join(updated)}" if updated else "."))
    if review:
        print(f"Left as they are, review with --diff: {', '.join(review)}")


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
    parser.add_argument("--status", action="store_true", help="compare the copied files with the current templates")
    parser.add_argument("--diff", nargs="*", metavar="FILE", help="print your files against the current templates (default: all that differ)")
    parser.add_argument("--update", action="store_true", help="overwrite files the plugin changed and you didn't edit")
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
    if args.status:
        print_status(target, deps)
        return 0
    if args.diff is not None:
        print_diff(target, deps, args.diff)
        return 0
    if args.update:
        update(target, deps)
        return 0

    stamp = read_stamp(target)
    version = plugin_version()
    copied, kept, changed, needs_cupertino = [], [], [], False
    for rel in KITS[args.kit]:
        dest = target / rel
        source = (TEMPLATES / rel).read_text(encoding="utf-8")
        text = adapt_text(source, deps)
        if dest.exists() and not args.force:
            kept.append(rel)
            # A kept file that already equals the template is recorded too.
            if rel not in stamp["files"] and dest.read_text(encoding="utf-8") == text:
                stamp["files"][rel] = {"version": version, "sha256": digest(text)}
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        dest.write_text(text, encoding="utf-8")
        stamp["files"][rel] = {"version": version, "sha256": digest(text)}
        copied.append(dest)
        if text != source:
            changed.append(dest)
        needs_cupertino = needs_cupertino or "package:cupertino_ui/" in text

    present = write_barrel(target)
    write_stamp(target, stamp)

    print(f"Copied {len(copied)} file(s) of the {args.kit} kit to {target} (flutter-modern-ui {version}).")
    if kept:
        print(f"Kept {len(kept)} existing file(s) (--status compares them, --force overwrites): {', '.join(kept)}")
    print(f"{BARREL} exports {len(present)} file(s).")
    if changed:
        print(f"Imports rewritten for material_ui in {len(changed)} file(s).")
    if needs_cupertino and "cupertino_ui" not in deps:
        print("app_theme.dart needs CupertinoPageTransitionsBuilder: flutter pub add cupertino_ui")
    print("Next: set AppTheme.config (seed, variant, font, script, motion level), wire AppTheme.light/dark and AppMessenger.key in MaterialApp, write DESIGN.md.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

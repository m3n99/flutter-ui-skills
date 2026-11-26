#!/usr/bin/env python3
"""CI only: lint_ui.py finds what its docstring says it finds, and skips what
it says it skips. Run from the repo root: python3 ci/lint_selftest.py"""

import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent / "plugins/flutter-modern-ui/skills/flutter-modern-ui/scripts"))
import lint_ui  # noqa: E402

RULES = [*lint_ui.COMPILED, lint_ui.token_math_rule(["Corners"])]


UI = "import 'package:flutter/material.dart';\n"


def rules_found(source, path="lib/features/home/screen.dart"):
    text = source if "import " in source else UI + source
    offset = 0 if "import " in source else 1
    return [(number - offset, rule) for _, number, rule, _, _ in lint_ui.lint_text(Path(path), text, RULES)]


CASES = [
    ("a raw value on its own line inside a call", "Padding(\n  padding: EdgeInsets.only(\n    top: AppSpace.md,\n    bottom: 12,\n  ),\n)", [(4, "raw-spacing")]),
    ("a raw icon size two lines down", "Icon(\n  Icons.add,\n  size: 20,\n)", [(3, "raw-size")]),
    ("token arithmetic on App* names", "final gap = AppSpace.xs + 2;", [(1, "token-math")]),
    ("token arithmetic on the project's own names", "final gap = Gaps.s8 + 3;", [(1, "token-math")]),
    ("token arithmetic on a class named with --tokens", "final r = Corners.card - 4;", [(1, "token-math")]),
    ("arithmetic that isn't on tokens", "final next = Page.index + 1;", []),
    ("a value inside a comment", "// EdgeInsets.all(12) was the old padding\nfinal a = 1;", []),
    ("a value inside a block comment", "/* Color(0xFF112233) */\nfinal a = 1;", []),
    ("a `//` inside a string is not a comment", "final url = 'https://example.com'; final c = Colors.red;", [(1, "raw-color")]),
    ("a suppressed line", "final c = Color(0xFF1F2A44); // lint-ui: ok (brand seed)", []),
    ("a suppressed value inside a multi-line call", "SizedBox(\n  height: 3, // lint-ui: ok (hairline pair)\n)", []),
    ("tokens only", "Padding(padding: EdgeInsets.all(AppSpace.md), child: SizedBox(height: AppSpace.xs))", []),
    ("left and right", "Positioned(\n  left: 0,\n  child: x,\n)", [(2, "left-right")]),
]

DURATION = "final d = Duration(seconds: 30);"
DURATION_CASES = [
    ("a duration in a screen", rules_found(DURATION), [(1, "raw-duration")]),
    ("a sync interval in data/", rules_found(DURATION, "lib/data/sync_service.dart"), []),
    ("a debounce in use_cases/", rules_found(DURATION, "lib/use_cases/push.dart"), []),
    ("a delay in test/", rules_found(DURATION, "test/sync_test.dart"), []),
    ("a file with no Flutter import", rules_found("import 'dart:async';\nfinal d = Duration(seconds: 2);", "lib/core/lock.dart"), []),
    ("material_ui counts as Flutter UI", rules_found("import 'package:material_ui/material_ui.dart';\nfinal d = Duration(milliseconds: 300);"), [(2, "raw-duration")]),
]

SKIPPED = ["lib/core/tokens.dart", "lib/design_system/app_theme.dart", "lib/ui/color_palette.dart", "lib/models/user.g.dart"]
LINTED = ["lib/features/settings/theme_picker_screen.dart", "lib/features/density_demo/page.dart", "lib/widgets/palette_swatch.dart"]


def diff_with_arabic():
    """--diff on a change with Arabic in it (it crashed on Windows: git's
    output was decoded with the ANSI code page)."""
    import os
    import subprocess
    import tempfile

    script = Path(lint_ui.__file__)
    with tempfile.TemporaryDirectory() as folder:
        root = Path(folder)

        def git(*args):
            subprocess.run(["git", "-C", str(root), *args], check=True, capture_output=True)

        git("init", "-q")
        (root / "lib").mkdir()
        screen = root / "lib" / "screen.dart"
        screen.write_text(UI + "final a = 1;\n", encoding="utf-8")
        git("add", ".")
        git("-c", "user.email=ci@example.com", "-c", "user.name=ci", "commit", "-qm", "start")
        screen.write_text(UI + "final a = 1;\nfinal t = Text('مسح ضوئي', style: TextStyle(fontSize: 14));\n", encoding="utf-8")
        env = dict(os.environ, PYTHONIOENCODING="", PYTHONUTF8="0")
        run = subprocess.run(
            [sys.executable, str(script), "--diff"], cwd=root, capture_output=True, env=env
        )
        out = run.stdout.decode("utf-8", errors="replace")
        if run.returncode != 1 or "font-size" not in out or "مسح ضوئي" not in out:
            return [f"--diff with Arabic in the change: exit {run.returncode}, output {out[-300:]!r} {run.stderr.decode('utf-8', 'replace')[-300:]!r}"]
    return []


def main():
    failures = []
    for name, source, expected in CASES:
        found = rules_found(source)
        if found != expected:
            failures.append(f"{name}: expected {expected}, found {found}")
    for name, found, expected in DURATION_CASES:
        if found != expected:
            failures.append(f"{name}: expected {expected}, found {found}")
    failures += diff_with_arabic()
    for path in SKIPPED:
        if not lint_ui.skipped(Path(path)):
            failures.append(f"{path} should be skipped (it defines tokens or is generated)")
    for path in LINTED:
        if lint_ui.skipped(Path(path)):
            failures.append(f"{path} should be linted (it is a screen or a widget)")
    if not lint_ui.skipped(Path("lib/ui/colors.dart"), ["lib/ui/colors.dart"]):
        failures.append("--skip should skip the file it names")
    for failure in failures:
        print(f"FAIL {failure}")
    total = len(CASES) + len(DURATION_CASES) + 1 + len(SKIPPED) + len(LINTED) + 1
    print(f"{total - len(failures)} passed, {len(failures)} failed")
    return 1 if failures else 0


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Check Dart UI code against the non-negotiables that a grep can see.

    python3 lint_ui.py                      # every .dart file under lib/
    python3 lint_ui.py lib/features/bills   # some folders or files
    python3 lint_ui.py --diff               # only lines changed since HEAD (plus new files)
    python3 lint_ui.py --diff origin/main   # only lines this branch changed

Flags raw colors, font sizes, spacing, sizes, radii, opacities and durations,
token arithmetic (`AppSpace.xs + 2`), and left/right APIs where start/end
exist. It reads one line at a time, so it misses what spans lines; it's a
cheap first pass before the review, not a replacement for it.

The files that define the tokens and the theme (tokens, theme, palette,
typography, density) and generated files are skipped. Silence a deliberate
exception with a trailing `// lint-ui: ok` (say why) on the line.

Exit codes: 0 clean, 1 findings, 2 error.
"""

import argparse
import re
import subprocess
import sys
from pathlib import Path

RULES = [
    ("raw-color", r"(?<![\w.])Colors\.(?!transparent\b)[a-z]", "raw color: use a ColorScheme role or a palette tone"),
    ("raw-color", r"\bColor\(\s*0x[0-9A-Fa-f]{6,8}\s*\)", "raw color: use a ColorScheme role or a palette tone"),
    ("raw-color", r"\bColor\.from(?:ARGB|RGBO)\(", "raw color: use a ColorScheme role or a palette tone"),
    ("font-size", r"\bfontSize:\s*\d", "raw font size: use a TextTheme role"),
    (
        "raw-spacing",
        r"\bEdgeInsets(?:Directional)?\.(?:all|symmetric|only|fromLTRB|fromSTEB)\([^)]*?(?<![\w.])(?:[1-9]\d*(?:\.\d+)?|0\.\d*[1-9])\b",
        "raw spacing: use AppSpace tokens",
    ),
    ("raw-size", r"\b(?:SizedBox|Container|Icon)\([^)]*?\b(?:width|height|size):\s*[1-9]", "raw size: use a token (AppSize, AppSpace, AppIcon)"),
    ("raw-size", r"\b(?:max|min)(?:Width|Height):\s*[1-9]", "raw constraint: use a token (AppSize)"),
    ("token-math", r"\bApp(?:Space|Radius|Size|Stroke)\.\w+\s*[-+]\s*\d", "token ± number: use the next token step, or add a token"),
    ("raw-radius", r"\b(?:BorderRadius|Radius)\.circular\(\s*[1-9]", "raw radius: use AppRadius"),
    ("raw-opacity", r"\.withValues\(\s*alpha:\s*(?:0?\.\d+|1\.0\b)", "raw opacity: use AppOpacity"),
    ("raw-opacity", r"\.withOpacity\(", "withOpacity is deprecated: withValues(alpha: AppOpacity...)"),
    ("raw-duration", r"\bDuration\(\s*(?:milliseconds|seconds):\s*[1-9]", "raw duration: use AppDurations through context.motion"),
    ("left-right", r"\bEdgeInsets\.only\([^)]*\b(?:left|right):", "left/right padding: EdgeInsetsDirectional (start/end)"),
    ("left-right", r"\bEdgeInsets\.fromLTRB\(", "left/right padding: EdgeInsetsDirectional.fromSTEB"),
    ("left-right", r"\bAlignment\.(?:centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)\b", "left/right alignment: AlignmentDirectional"),
    ("left-right", r"\bTextAlign\.(?:left|right)\b", "left/right text: TextAlign.start / end"),
    ("left-right", r"\bPositioned\([^)]*\b(?:left|right):", "left/right position: PositionedDirectional (start/end)"),
]
COMPILED = [(rule, re.compile(pattern), message) for rule, pattern, message in RULES]

SKIP_NAME = re.compile(r"(tokens|theme|palette|typography|density)[^/]*\.dart$|\.(g|freezed|gr|mocks)\.dart$")
SUPPRESS = "lint-ui: ok"


def skipped(path):
    return bool(SKIP_NAME.search(path.as_posix()))


def lint_line(path, number, line):
    stripped = line.strip()
    if not stripped or stripped.startswith(("//", "*", "/*")) or SUPPRESS in line:
        return []
    return [(path, number, rule, message, stripped) for rule, pattern, message in COMPILED if pattern.search(line)]


def lint_files(paths):
    findings = []
    for path in paths:
        if skipped(path):
            continue
        for number, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), start=1):
            findings += lint_line(path, number, line)
    return findings


def dart_files(targets):
    files = []
    for target in targets:
        path = Path(target)
        if path.is_dir():
            files += sorted(path.rglob("*.dart"))
        elif path.suffix == ".dart" and path.is_file():
            files.append(path)
    return files


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


def lint_diff(base):
    findings = []
    path = None
    number = 0
    for line in git("diff", "-U0", base, "--", "*.dart").splitlines():
        if line.startswith("+++ "):
            name = line[4:]
            path = Path(name[2:]) if name.startswith("b/") else None
        elif line.startswith("@@"):
            match = re.search(r"\+(\d+)", line)
            number = int(match.group(1)) if match else 0
        elif line.startswith("+") and path is not None:
            if not skipped(path):
                findings += lint_line(path, number, line[1:])
            number += 1
    untracked = [Path(name) for name in git("ls-files", "--others", "--exclude-standard", "--", "*.dart").splitlines()]
    return findings + lint_files(untracked)


def main():
    parser = argparse.ArgumentParser(description="Grep-level check of the UI non-negotiables.")
    parser.add_argument("paths", nargs="*", help="files or folders (default: lib)")
    parser.add_argument("--diff", nargs="?", const="HEAD", metavar="BASE", help="only lines changed since BASE (default HEAD)")
    args = parser.parse_args()

    try:
        findings = lint_diff(args.diff) if args.diff else lint_files(dart_files(args.paths or ["lib"]))
    except (subprocess.CalledProcessError, FileNotFoundError) as error:
        print(f"git failed: {error}", file=sys.stderr)
        return 2

    for path, number, rule, message, source in findings:
        print(f"{path.as_posix()}:{number}: {rule}: {message}\n    {source}")
    if findings:
        counts = {}
        for _, _, rule, _, _ in findings:
            counts[rule] = counts.get(rule, 0) + 1
        summary = ", ".join(f"{rule} {count}" for rule, count in sorted(counts.items()))
        print(f"\n{len(findings)} finding(s): {summary}. Fix them, or mark a deliberate one with // {SUPPRESS} (and why).")
        return 1
    print("No findings.")
    return 0


if __name__ == "__main__":
    sys.exit(main())

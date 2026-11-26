#!/usr/bin/env python3
"""Check Dart UI code against the non-negotiables that a grep can see.

    python3 lint_ui.py                      # every .dart file under lib/
    python3 lint_ui.py lib/features/bills   # some folders or files
    python3 lint_ui.py --diff               # only lines changed since HEAD (plus new files)
    python3 lint_ui.py --diff origin/main   # only lines this branch changed

    python3 lint_ui.py --tokens Gaps Corners   # the project's own token classes
    python3 lint_ui.py --skip 'lib/ui/colors.dart'   # one more token file

Flags raw colors, font sizes, spacing, sizes, radii, opacities and durations,
token arithmetic (`AppSpace.xs + 2`), and left/right APIs where start/end
exist. A call is read whole, so a raw value on its own line inside
`EdgeInsets.only(` or `Icon(` is found.

What it does not see (the review and the screenshots do):
- a value behind a nested call: in `Container(padding: EdgeInsets.all(x),
  width: 40)` the scan of `Container(` stops at the first `)`;
- values passed through variables, constants or helper functions;
- raw numbers in places it has no rule for (`Offset`, `Transform`,
  `BoxConstraints.tightFor`, custom painters);
- token arithmetic on a class whose name gives no hint that it holds tokens:
  it knows `App*` and names containing Space, Gap, Pad, Inset, Radius,
  Corner, Size, Dimen or Stroke; name others with --tokens.
A clean run means none of the patterns below matched, not that the screen
follows the design system.

`raw-duration` only applies to presentation code: files that import
Flutter's widgets (material, widgets, cupertino, material_ui) outside
test/, data/, domain/, repos/, use_cases/, services/ and similar folders.
A sync interval or a debounce there is timing, not motion.

Skipped: the files that define the tokens and the theme, by exact name
(`tokens.dart`, `app_theme.dart`, `color_palette.dart`: the name ends with
tokens, theme, palette, typography or density), generated files, and
anything matching --skip. `theme_picker_screen.dart` is a screen and is
linted. Silence a deliberate exception with a trailing `// lint-ui: ok`
(say why) on the line of the value.

Exit codes: 0 clean, 1 findings, 2 error.
"""

import argparse
import fnmatch
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

# Rules about how the interface looks and moves. In code with no interface
# (a sync interval, a debounce, a file-lock wait, test delays) a Duration is
# timing, not motion, and there is no BuildContext to scale it with.
UI_ONLY = {"raw-duration"}
NON_UI_FOLDERS = re.compile(r"(?:^|/)(?:test|integration_test|data|domain|repos|repositories|use_?cases|services|infrastructure|sync|jobs|workers|api)/", re.I)
UI_IMPORT = re.compile(r"""import\s+['"]package:(?:flutter/(?:material|widgets|cupertino)|material_ui/|cupertino_ui/)""")


def is_ui_file(path, text):
    """True for presentation code: not in a non-UI folder (data, domain,
    use_cases, test...) and imports Flutter's widgets."""
    return not NON_UI_FOLDERS.search(path.as_posix()) and bool(UI_IMPORT.search(text))

# Token classes by name: the templates' App* classes, and names that say what
# they hold (Gaps, Insets, Corners, Dimens). --tokens adds the rest.
TOKEN_HINT = r"App[A-Z]\w*|(?:[A-Z]\w*)?(?:Space|Spacing|Gap|Pad|Inset|Radius|Radii|Corner|Size|Dimen|Stroke)\w*"
TOKEN_MATH_MESSAGE = "token ± number: use the next token step, or add a token"

# Token and theme files: the name ends with one of these words.
SKIP_NAME = re.compile(r"(?:^|[/_])(?:tokens|theme|palette|typography|density)\.dart$|\.(g|freezed|gr|mocks)\.dart$")
SUPPRESS = "lint-ui: ok"


def token_math_rule(extra=()):
    names = "|".join([TOKEN_HINT, *(re.escape(name) for name in extra)])
    return ("token-math", re.compile(rf"\b(?:{names})\.\w+\s*[-+]\s*\d"), TOKEN_MATH_MESSAGE)


def skipped(path, extra=()):
    name = path.as_posix()
    return bool(SKIP_NAME.search(name)) or any(fnmatch.fnmatch(name, pattern) for pattern in extra)


def blank_comments(text):
    """The text with comments replaced by spaces (line numbers and columns
    stay), so a rule never matches inside one and a `)` in a comment never
    ends a call. Strings are kept: a `//` inside quotes is not a comment."""
    out = []
    i, n = 0, len(text)
    quote = None
    while i < n:
        c = text[i]
        if quote:
            out.append(c)
            if c == "\\" and i + 1 < n:
                out.append(text[i + 1])
                i += 2
                continue
            if c == quote or c == "\n":
                quote = None
            i += 1
        elif c in "'\"":
            quote = c
            out.append(c)
            i += 1
        elif text.startswith("//", i):
            end = text.find("\n", i)
            end = n if end < 0 else end
            out.append(" " * (end - i))
            i = end
        elif text.startswith("/*", i):
            end = text.find("*/", i + 2)
            end = n if end < 0 else end + 2
            out.append("".join(ch if ch == "\n" else " " for ch in text[i:end]))
            i = end
        else:
            out.append(c)
            i += 1
    return "".join(out)


def lint_text(path, text, rules, only_lines=None):
    """Findings in one file. A match is reported on the line where it ends:
    the line of the raw value. [only_lines] keeps the findings on those lines
    (--diff)."""
    lines = text.splitlines()
    code = blank_comments(text)
    starts = [0]
    for line in code.splitlines(keepends=True):
        starts.append(starts[-1] + len(line))

    def line_of(offset):
        low, high = 0, len(starts) - 1
        while low < high:
            mid = (low + high + 1) // 2
            if starts[mid] <= offset:
                low = mid
            else:
                high = mid - 1
        return low + 1

    seen, findings = set(), []
    ui_file = is_ui_file(path, text)
    for rule, pattern, message in rules:
        if rule in UI_ONLY and not ui_file:
            continue
        for match in pattern.finditer(code):
            number = line_of(max(match.start(), match.end() - 1))
            if number > len(lines) or (number, rule) in seen:
                continue
            first = line_of(match.start())
            if any(SUPPRESS in lines[n - 1] for n in range(first, number + 1)):
                continue
            if only_lines is not None and number not in only_lines:
                continue
            seen.add((number, rule))
            findings.append((path, number, rule, message, lines[number - 1].strip()))
    return sorted(findings, key=lambda finding: finding[1])


def lint_files(paths, rules, skip=()):
    findings = []
    for path in paths:
        if skipped(path, skip):
            continue
        findings += lint_text(path, path.read_text(encoding="utf-8", errors="replace"), rules)
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
    return subprocess.run(["git", *args], capture_output=True, encoding="utf-8", errors="replace", check=True).stdout


def lint_diff(base, rules, skip=()):
    """Findings on the lines changed since [base]. Each changed file is read
    whole from the working tree, so a call that spans lines is still seen."""
    changed = {}
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
            changed.setdefault(path, set()).add(number)
            number += 1
    root = Path(git("rev-parse", "--show-toplevel").strip())
    findings = []
    for path, numbers in changed.items():
        file = root / path
        if skipped(path, skip) or not file.is_file():
            continue
        findings += lint_text(path, file.read_text(encoding="utf-8", errors="replace"), rules, only_lines=numbers)
    untracked = [Path(name) for name in git("ls-files", "--others", "--exclude-standard", "--", "*.dart").splitlines()]
    return findings + lint_files(untracked, rules, skip)


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
    parser = argparse.ArgumentParser(description="Grep-level check of the UI non-negotiables.")
    parser.add_argument("paths", nargs="*", help="files or folders (default: lib)")
    parser.add_argument("--diff", nargs="?", const="HEAD", metavar="BASE", help="only lines changed since BASE (default HEAD)")
    parser.add_argument("--tokens", nargs="+", default=[], metavar="CLASS", help="the project's token classes, for the token ± number rule (App* and names like Gaps, Insets, Corners are known)")
    parser.add_argument("--skip", action="append", default=[], metavar="GLOB", help="also skip files matching this path glob (repeatable)")
    args = parser.parse_args()
    rules = [*COMPILED, token_math_rule(args.tokens)]

    try:
        if args.diff:
            findings = lint_diff(args.diff, rules, args.skip)
        else:
            findings = lint_files(dart_files(args.paths or ["lib"]), rules, args.skip)
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

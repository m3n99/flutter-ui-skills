# Contributing

## The best contribution: real-project feedback

Use the skills on a real app, keep a log with [`docs/feedback-template.md`](docs/feedback-template.md), and open an issue or PR with its **open** entries. Versions 1.0 to 1.3 came out of exactly such logs; concrete findings ("the template says X at `file:line`, the app needed Y, suggest Z") turn into fixes quickly. Each release's changelog names the findings it took in, so you can mark them **fixed in x.y.z**.

## Rules for changes

- **Measure changes to the skills' text.** `plugins/flutter-modern-ui/evals/` holds one case per behaviour the skills must cause (asking about the look and the motion level before building, deciding the look from the subject, a home screen that answers its question, catching a button on the navigation bar, errors inside sheets, stacking rows at big fonts, using the project's own tokens, interface wording, Arabic wording). Each case is a prompt a user would type, plus graders: a regex or a judged rubric on the reply, and whether one of the plugin's skills was loaded.

  ```bash
  cd plugins/flutter-modern-ui
  claude plugin eval . --tag smoke --runs 1 --ablation none     # four quick cases while editing
  claude plugin eval . --runs 3                                 # the whole suite, with and without the plugin
  ```

  It starts Claude sessions on your account (the whole suite once with a baseline cost about $1 in November 2026). When a feedback log shows Claude doing the wrong thing despite the skill, add a case for it first, then fix the wording until the case passes. Prefer regex graders for anything a pattern can check; keep judged rubrics short, with concrete PASS and FAIL conditions.

- **Concrete over adjectives.** A rule names values, widgets and files ("radius 12 − 8 = 4 for rows in a group card"), not "make it clean".
- **One source of truth.** Values live in `tokens.md` / the templates; other references point there instead of repeating numbers.
- **Templates compile on current stable Flutter** and pass the sandbox tests:

  ```bash
  bash scripts/sandbox.sh --material-ui          # or --framework-material; CI runs both
  cd build/sandbox
  flutter analyze
  flutter test test/ui test/pdf test/ci
  flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true   # then look at the screenshots
  python3 ../../plugins/flutter-modern-ui/skills/flutter-ui-verify/scripts/rasterize_pdf.py test/pdf/out   # and at the printed pages
  ```

  The sandbox gets the templates through the same copy scripts users run (`copy_design_system.py --kit all`, `copy_harness.py`), so a change to a kit list or an import rewrite is tested too. With `--material-ui` every Material import becomes `package:material_ui/material_ui.dart`; with `--framework-material` the app keeps `package:flutter/material.dart`. Templates must compile both ways.

  `test/ci/` holds tests for the repo itself (from `ci/`): the example screens' promised behaviour and the PDF checks catching what they should. They aren't part of the harness users copy.

- **Examples are references**: realistic data, every state, no shortcuts we'd flag in a review. They and the widgets pass the lint and the glyph check:

  ```bash
  python3 plugins/flutter-modern-ui/skills/flutter-modern-ui/scripts/lint_ui.py plugins/flutter-modern-ui/skills/flutter-modern-ui/assets
  python3 plugins/flutter-modern-ui/skills/flutter-ui-verify/scripts/check_glyphs.py --font <IBMPlexSansArabic-Regular.ttf> plugins/flutter-modern-ui/skills/flutter-modern-ui/assets
  ```
- **A new template file joins a kit** (`KITS` in `copy_design_system.py`): core when every app needs it, extras otherwise.
- **Skills stay lean**: SKILL.md holds the workflow and rules; details go in `references/`, loaded only when needed.
- **Presentation only**: the skills never change a project's state management, routing or DI.
- **No new packages in the design-system templates.** Recipes may mention packages, with when and why. The one exception is the printed-document example and its harness, which need `pdf`.
- Relative paths between skills (`../flutter-motion/…`) must resolve; CI checks them.
- Update `CHANGELOG.md`.

## Releasing

Bump the version in `plugins/flutter-modern-ui/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (both places), update the changelog, tag `vX.Y.Z`.

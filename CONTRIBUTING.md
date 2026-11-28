# Contributing

## The best contribution: real-project feedback

Use the skills on a real app, keep a log with [`docs/feedback-template.md`](docs/feedback-template.md), and open an issue or PR with its **open** entries. Versions 1.0 to 1.3 came out of exactly such logs; concrete findings ("the template says X at `file:line`, the app needed Y, suggest Z") turn into fixes quickly. Each release's changelog names the findings it took in, so you can mark them **fixed in x.y.z**.

## Rules for changes

- **Measure changes to the skills' text.** `plugins/flutter-modern-ui/evals/` holds one case per behaviour: what the skills must cause (asking about the look and the motion level before building, deciding the look from the subject, a home screen that answers its question, catching a button on the navigation bar, errors inside sheets, stacking rows at big fonts, using the project's own tokens, interface and Arabic wording, the chart that fits the question, a submit button left enabled), which skill a request should load (verify, motion, audit), and when the plugin must stay small or stay out (a one-line question answered without an intake round, a motion level that was stated and isn't asked again, a React question and a build failure that load no skill). Each case is a prompt a user would type, plus graders: a regex or a judged rubric on the reply or on a file, and which skill was loaded.

  ```bash
  cd plugins/flutter-modern-ui
  claude plugin eval . --tag smoke --runs 1 --ablation none     # five quick cases while editing
  claude plugin eval . --tag reply --runs 3                     # every reply-graded case, with and without the plugin
  claude plugin eval . --tag build --runs 3 --scaffold --allow-tools Write Edit   # the case that writes a screen into a fixture project
  ```

  It starts Claude sessions on your account (the nine reply cases of 1.4, once with a baseline, cost about $1 in November 2026). `--scaffold` runs the case's `fixture.sh` on your machine to seed the workspace; it only writes files. When a feedback log shows Claude doing the wrong thing despite the skill, add a case for it first, then fix the wording until the case passes. Prefer regex graders for anything a pattern can check, written so the order of the answer doesn't matter; keep judged rubrics short, with concrete PASS and FAIL conditions. A `skill-fired` grader names the skill the request should load, not all five.

  **Record the baseline with a release.** Results are git-ignored (`evals/results/`). After a full run, copy the summary table (case, with, without, Δ, runs) into the release's changelog entry, with the date and the model, so the repo shows what the plugin changes and a later release can be compared with it. The cases added in 1.5 were written against the documented case format and had not been run when they were committed: fix a grader that misfires before trusting its score.

- **Concrete over adjectives.** A rule names values, widgets and files ("radius 12 − 8 = 4 for rows in a group card"), not "make it clean".
- **One source of truth.** Values live in `tokens.md` / the templates (motion numbers in `AppMotion`); other references point there instead of repeating numbers. A rule that several files must state (the reviewer agent can't read the references, so it carries its own copy of the review list) gets a CI check that the copies agree. When a reference and a template disagree, the template is right and the reference is the bug.
- **Say what a check covers.** A new check documents what it does not see (`harness.md` › What the checks do not see, the docstring of `lint_ui.py`) and gets a test in `ci/` showing it fail on a broken case and pass on the fixed one.
- **Taste is a default.** A rule that protects correctness, accessibility or the project's own system is stated as a rule. A preference (flat cards, labels above fields, 8 px clear of the bars) is marked *house default*, and `DESIGN.md` overrides it.
- **Templates compile on the pinned Flutter** (`FLUTTER_VERSION` in `.github/workflows/ci.yml`; the fonts are pinned in `scripts/fetch_fonts.sh`) and pass the sandbox tests. Moving a pin is its own change: bump it, run CI, look at the screenshots.

  ```bash
  bash scripts/sandbox.sh --material-ui          # or --framework-material; CI runs both
  cd build/sandbox
  flutter analyze
  flutter test test/ui test/pdf test/ci
  flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true   # then look at the screenshots
  python3 ../../plugins/flutter-modern-ui/skills/flutter-ui-verify/scripts/rasterize_pdf.py test/pdf/out   # and at the printed pages
  ```

  The sandbox gets the templates through the same copy scripts users run (`copy_design_system.py --kit all`, `copy_harness.py`), so a change to a kit list or an import rewrite is tested too. With `--material-ui` every Material import becomes `package:material_ui/material_ui.dart`; with `--framework-material` the app keeps `package:flutter/material.dart`. Templates must compile both ways.

  `test/ci/` holds tests for the repo itself (from `ci/`): the example screens' promised behaviour, the harness failing on what it must catch (an overflow with its source line, a stuck picker, a button under the keyboard) and staying quiet where it should (Cupertino bars, an endless list), and the PDF checks. They aren't part of the harness users copy. `python3 ci/lint_selftest.py` does the same for the linter.

- **Examples are references**: realistic data, every state, no shortcuts we'd flag in a review: no handler that does nothing, no field that is validated and then dropped, no count that disagrees with the data, and the destructive action never the easiest one to hit. They and the widgets pass the lint and the glyph check:

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

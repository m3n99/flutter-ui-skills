# Contributing

## The best contribution: real-project feedback

Use the skills on a real app, keep a log with [`docs/feedback-template.md`](docs/feedback-template.md), and open an issue or PR with its **open** entries. Versions 1.0 and 1.1 came out of exactly such logs; concrete findings ("the template says X at `file:line`, the app needed Y, suggest Z") turn into fixes quickly. Each release's changelog names the findings it took in, so you can mark them **fixed in x.y.z**.

## Rules for changes

- **Concrete over adjectives.** A rule names values, widgets and files ("radius 12 − 8 = 4 for rows in a group card"), not "make it clean".
- **One source of truth.** Values live in `tokens.md` / the templates; other references point there instead of repeating numbers.
- **Templates compile on current stable Flutter** and pass the sandbox tests:

  ```bash
  bash scripts/sandbox.sh
  cd build/sandbox
  flutter analyze
  flutter test test/ui test/pdf test/ci
  flutter test test/ui/visual_test.dart --update-goldens --dart-define=VISUAL=true   # then look at the screenshots
  python3 ../../plugins/flutter-modern-ui/skills/flutter-ui-verify/scripts/rasterize_pdf.py test/pdf/out   # and at the printed pages
  ```

  `test/ci/` holds tests for the repo itself (from `ci/`): the example screens' promised behaviour and the PDF checks catching what they should. They aren't part of the harness users copy.

- **Examples are references**: realistic data, every state, no shortcuts we'd flag in a review.
- **Skills stay lean**: SKILL.md holds the workflow and rules; details go in `references/`, loaded only when needed.
- **Presentation only**: the skills never change a project's state management, routing or DI.
- **No new packages in the design-system templates.** Recipes may mention packages, with when and why. The one exception is the printed-document example and its harness, which need `pdf`.
- Relative paths between skills (`../flutter-motion/…`) must resolve; CI checks them.
- Update `CHANGELOG.md`.

## Releasing

Bump the version in `plugins/flutter-modern-ui/.claude-plugin/plugin.json` and `.claude-plugin/marketplace.json` (both places), update the changelog, tag `vX.Y.Z`.

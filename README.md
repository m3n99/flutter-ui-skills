# flutter-ui-skills

[![CI](https://github.com/m3n99/flutter-ui-skills/actions/workflows/ci.yml/badge.svg)](https://github.com/m3n99/flutter-ui-skills/actions/workflows/ci.yml)

**Flutter UI engineering skills for Claude Code.** They don't just make screens look modern. They make Claude work like a UI engineer joining your team:

1. **Study** the app first: its design system, its names, its state flow, its decisions.
2. **Agree on the system**: extend the one you have, or set one up (from a direction or from screenshots of apps you like), written down in a `DESIGN.md` contract.
3. **Build** consistent screens for phone, tablet and desktop, RTL included.
4. **Animate** with purpose: entrances, list insert/remove, charts, buttons, transitions.
5. **Verify by looking**: render every screen across sizes, text scales, themes, platforms and directions, catch overflows with the source line, then open the screenshots and review them like a designer.
6. **Record** the decisions so the next session stays consistent.

## What's inside

One plugin, five skills and a reviewer agent:

| | What it does | Use it when |
|---|---|---|
| `flutter-modern-ui` | The hub. Step 0 reads the project's design system and DESIGN.md, asks once about platforms / RTL / emoji / motion, then builds on the existing system with 17 focused references | any Flutter UI work |
| `flutter-design-system` | Creates, extends, repairs or documents the design system: tokens, theme, density, shared components, `DESIGN.md`. Studies existing code (inventory script) or reference screenshots | new apps, inconsistent apps, "make it look like these" |
| `flutter-motion` | Purposeful animation through a few shared pieces: entrances, `AnimatedItems`, state switches, counters, progress, charts, buttons, transitions, micro-interactions | "add animations", "make it feel alive", janky motion |
| `flutter-ui-verify` | A `flutter_test` harness: layout matrix, sheet / keyboard / tap-target checks, contrast test, screenshots Claude opens and reviews | after any UI change, before saying "done" |
| `flutter-ui-audit` | Reviews existing screens, reports findings with evidence, fixes them presentation-only, proves it with before/after screenshots | "review / polish / modernize this screen" |
| `flutter-ui-reviewer` (agent) | Independent visual QA on the screenshots against DESIGN.md | larger passes, so the work isn't grading itself |

```
plugins/flutter-modern-ui/
├── agents/flutter-ui-reviewer.md
└── skills/
    ├── flutter-modern-ui/
    │   ├── SKILL.md
    │   ├── references/      discovery · intake · directions · tokens · theming · layout · adaptive ·
    │   │                    components · forms · sheets-dialogs · data-display · states · messages ·
    │   │                    rtl-arabic · accessibility · anti-patterns (53) · review-checklist
    │   └── assets/
    │       ├── design_system/   drop-in Dart: tokens, density, palette, typography, theme, widgets, motion
    │       └── examples/        dashboard · records list-detail · long form · app shell
    ├── flutter-design-system/   SKILL.md · study-existing-app · study-reference-apps ·
    │                            scripts/ui_inventory.sh · templates/DESIGN.md · templates/UI_PASS.md
    ├── flutter-motion/          SKILL.md · principles · recipes (17 surfaces) · testing · packages
    ├── flutter-ui-verify/       SKILL.md · harness · visual-review · golden-pitfalls · assets/harness/*.dart
    └── flutter-ui-audit/        SKILL.md
```

### Drop-in design system (`assets/design_system/`)

No third-party packages.

- **Tokens**: spacing, radius roles with a concentric-corner helper, elevation, strokes, opacity, sizes, breakpoints and window size classes, motion durations and M3 curves.
- **`AppThemeConfig`**: seed and scheme variant, font and fallback, **Arabic script** (zero letter-spacing, taller lines), **eye-comfort surfaces** (warm, dimmed, contrast-checked), **filled or outlined inputs**, touch and desktop density.
- **`AppTheme`**: light and dark, every common component themed, desktop scrollbars and tooltips, checkmarked chips, data tables, predictive-back page transitions.
- **`AppDensity`**: 48 px touch vs 40 px desktop controls, chosen by platform.
- **`AppPalette`**: success / warning / info tones (add your domain tones), soft and hover shadows.
- **Widgets**: `AppCard` (ink, hover, press scale, raised tiles), `StatusPill` (icon required), `IconBadge`, `EmojiBadge`, `SectionHeader`, `EmptyState`, `Shimmer` / `SkeletonBox` / `ShowAfter`, `Ltr`, `showAppSheet` + `SheetScaffold`, `AppChoiceChips`, `AppMessenger` (one message component, `persist: false`, failure helper, **delete with Undo**), `AdaptiveShell`, `ContentWidth`, `KpiTile` / `KpiGrid`.
- **Motion**: `Entrance`, `AnimatedItems` (diffing sliver list/grid that keeps item state), `StateSwitcher`, `SubmitButton`, `AnimatedNumber`, `AppProgressBar`, `ShakeOnChange`, `PopOnChange`, `MiniBarChart` + `NiceScale`.

### Verification harness (`flutter-ui-verify/assets/harness/`)

Copy into `test/ui/`, edit only `ui_cases.dart`, then:

```bash
flutter test test/ui                                                              # layout matrix, sheets, contrast
flutter test test/ui/visual_test.dart --update-goldens --dart-define=VISUAL=true  # screenshots → test/ui/screenshots/
```

A layout failure reads:

```
[360_light_android_rtl_x1.3] A RenderFlex overflowed by 13 pixels on the right.  ← lib/features/bills/bill_tile.dart:42
```

## Requirements

- Flutter **3.41 or newer** for the Dart templates (`SnackBar.persist`, `AppBarThemeData`, `InputDecorationThemeData`, `TickerMode.valuesOf`, `SizeTransition.alignment`). CI checks them on the current stable release. The skills tell Claude how to adapt to older SDKs.
- The skills themselves work with any Flutter project: in an app with its own design system, Claude maps these patterns onto your names instead of copying the templates.

## Install

### As a plugin (recommended)

In Claude Code:

```
/plugin marketplace add m3n99/flutter-ui-skills
/plugin install flutter-modern-ui@flutter-ui-skills
```

Update later with `/plugin marketplace update flutter-ui-skills`.

### As plain skills

```bash
git clone https://github.com/m3n99/flutter-ui-skills.git
# all projects
cp -r flutter-ui-skills/plugins/flutter-modern-ui/skills/* ~/.claude/skills/
# or one project (commit it so the team gets it too)
mkdir -p .claude/skills && cp -r flutter-ui-skills/plugins/flutter-modern-ui/skills/* .claude/skills/
# optional: the reviewer agent
mkdir -p .claude/agents && cp flutter-ui-skills/plugins/flutter-modern-ui/agents/*.md .claude/agents/
```

Keep the five skill folders side by side: they reference each other.

## Usage

The skills trigger on Flutter UI work; you can also call them by name.

```
Build the invoices screen: list grouped by status, filter sheet, delete with undo, list + detail on desktop.

Set up a design system for this app. Here are screenshots of three apps I like.

This app is Arabic-only and ships on Windows and Android. Make the dashboard consistent with the records screens.

/flutter-modern-ui:flutter-motion Add animations to the records list and the dashboard charts.

/flutter-modern-ui:flutter-ui-verify Check every screen and sheet at 360 px and text scale 1.3, then show me the screenshots.

/flutter-modern-ui:flutter-ui-audit lib/features/orders/ — report first, then fix the high and medium findings.
```

Tips:

- Answer the intake questions (platforms, RTL, emoji, motion) once; they land in `DESIGN.md` and later sessions read them.
- Commit `DESIGN.md`. It's how the tenth screen ends up looking like the first.
- The skills change presentation only. Your state management, routing and DI stay as they are.

## Contributing

Issues and PRs welcome, especially real-project feedback: use [`docs/feedback-template.md`](docs/feedback-template.md). Rules for changes are in [CONTRIBUTING.md](CONTRIBUTING.md); CI builds a sandbox app from the templates and runs `flutter analyze`, the UI tests and the screenshot pass on every PR.

```bash
bash scripts/sandbox.sh && cd build/sandbox && flutter analyze && flutter test test/ui
```

## License

MIT © Maen Khdour

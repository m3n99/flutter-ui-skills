# flutter-ui-skills

[![CI](https://github.com/m3n99/flutter-ui-skills/actions/workflows/ci.yml/badge.svg)](https://github.com/m3n99/flutter-ui-skills/actions/workflows/ci.yml)

**Flutter UI and UX skills for Claude Code.** They don't just make screens look modern. They make Claude work like a product designer and UI engineer joining your team:

1. **Study** the app first: its design system, its names, its state flow, its decisions.
2. **Write the brief**: what the app is, for whom, the one job it must make easy, and a signature element from its own world, so the look belongs to this app and not to a template.
3. **Agree on the system**: extend the one you have, or set one up (from the brief, a direction, or screenshots of apps you like), written down in a `DESIGN.md` contract.
4. **Plan the flow**: the task per screen, the fewest taps for the frequent ones, the words on the buttons.
5. **Build** consistent screens for phone, tablet and desktop, RTL included.
6. **Animate** with purpose, at the level you pick: entrances, list insert/remove, charts, buttons, transitions.
7. **Verify by looking**: render every screen across sizes, text scales, themes, platforms and directions, catch overflows with the source line, then open the screenshots and review them like a designer. Printed documents too: sample PDFs, checks for blocks that `pdf` drops or covers without an error, and every page rasterized and reviewed.
8. **Record** the decisions so the next session stays consistent.

The process is sized to the request. A question ("how should this button be worded?") gets an answer from the relevant reference. One widget gets a build, a lint of the diff and a render of its screen. A screen gets the plan and the full check. Only a first pass or a new app gets every step, and questions already answered in `DESIGN.md` or in the request (motion included) aren't asked again.

## What's inside

One plugin, five skills and a reviewer agent:

| | What it does | Use it when |
|---|---|---|
| `flutter-modern-ui` | The hub. Step 0 reads the project's design system and DESIGN.md, writes a five-line design brief, asks once about platforms / RTL / the look / emoji / how much motion and where, plans each screen's task and words, then builds on the existing system with 21 focused references (identity, UX, screen types and interface wording among them), keeps everything clear of the system bars, and lints its own diff | any Flutter UI or UX work, however small |
| `flutter-design-system` | Creates, extends, repairs or documents the design system: the brief, tokens, theme, density, shared components, `DESIGN.md`. Studies existing code (inventory script) or reference screenshots | new apps, inconsistent apps, apps that look like every other app, "make it look like these" |
| `flutter-motion` | Purposeful animation at the level the user picks (none, soft or expressive, asked with examples before building) through a few shared pieces: entrances, `AnimatedItems`, state switches, counters, progress, charts, buttons, transitions, micro-interactions | "add animations", "make it feel alive", janky motion |
| `flutter-ui-verify` | A `flutter_test` harness: layout matrix up to text scale 1.6, phones rendered under their system bars with a check that nothing touches them, sheet / keyboard / tap-target checks, contrast and soft-container test, rendered-screen accessibility (text contrast measured on the pixels, tap targets, labels), screenshots and contact sheets Claude opens and reviews, a glyph check for the app's fonts; sample PDFs with block checks, rasterized for review | after any UI or print-layout change, before saying "done" |
| `flutter-ui-audit` | Reviews existing screens for identity, flow, wording and visual craft, reports findings with evidence, fixes them presentation-only, proves it with before/after screenshots | "review / polish / modernize this screen", "is anything wrong with this?" |
| `flutter-ui-reviewer` (agent) | Independent design QA on the screenshots against the brief and DESIGN.md: whose app is this, does each screen do its job, do the words work, then the details | larger passes, so the work isn't grading itself |

```
plugins/flutter-modern-ui/
├── agents/flutter-ui-reviewer.md
├── evals/                   20 eval cases for `claude plugin eval` (what the skills must make Claude do, and when they must stay out)
└── skills/
    ├── flutter-modern-ui/
    │   ├── SKILL.md
    │   ├── references/      discovery · intake · identity · color · directions · ux · screens · writing ·
    │   │                    tokens · theming · layout · adaptive · components · forms · sheets-dialogs ·
    │   │                    data-display · states · messages · rtl-arabic · accessibility ·
    │   │                    anti-patterns (86) · review-checklist
    │   ├── scripts/         copy_design_system.py (core / extras kits, --status / --diff / --update) · lint_ui.py ·
    │   │                    palette.py (read, check, rank, preview and apply palettes)
    │   └── assets/
    │       ├── design_system/   drop-in Dart: tokens, density, palette, typography, theme, widgets, motion
    │       ├── palettes/        curated.json: 22 checked fallback palettes, tagged by subject and feeling
    │       └── examples/        one app built from its own brief: home (English and Arabic) · records list-detail ·
    │                            create / edit form · sign-in · settings · app shell · its signature as one
    │                            shared widget · printed invoice (PDF)
    ├── flutter-design-system/   SKILL.md · study-existing-app · study-reference-apps ·
    │                            scripts/ui_inventory.sh · templates/DESIGN.md · templates/UI_PASS.md
    ├── flutter-motion/          SKILL.md · principles · recipes (17 surfaces) · testing · packages
    ├── flutter-ui-verify/       SKILL.md · harness · visual-review · golden-pitfalls · printed-documents · preprinted-forms ·
    │                            assets/harness/*.dart · assets/pdf/*.dart ·
    │                            scripts/copy_harness.py · check_glyphs.py (--metrics) · rasterize_pdf.py · measure_pdf.py
    └── flutter-ui-audit/        SKILL.md
```

### A look that belongs to the app (`references/identity.md`, `ux.md`, `screens.md`, `writing.md`)

Tokens make an app consistent; they don't make it *this* app. Before any token is set, the skill writes a five-line brief and asks you to correct it:

> **Subject:** the order book where a neighbourhood bakery keeps tomorrow's pre-orders. **Audience:** the baker, before dawn, flour on the hands, quick looks between trays. **Job:** see what to bake tonight and for whom. **Feeling:** warm, plain, unhurried. **Signature:** each order set like a handwritten order slip.

The seed color, the typeface, the shapes and what the home screen shows come from that, and a **sameness check** throws out every line of the plan that would fit any other app (the default purple seed, Inter, a greeting over a grid of numbers). Then each screen gets a task sentence and a tap count (`ux.md`), the anatomy of its type (`screens.md`: home, detail, sign-in, onboarding, settings, search, paywall…), and its words written with the layout, not after it (`writing.md`, with Arabic conventions). The bundled examples are one such app: its home screen opens on "To collect" with the reminder action, drawn as ledger lines.

### Color from real palettes, not from memory (`references/color.md`, `scripts/palette.py`)

When you give no color, the skill doesn't pick one. It looks for the app's own first: the launcher icon, the splash, `colors.xml`, `manifest.json`. With none, it turns the brief's subject and feeling words into a search of real palette sources:

- [Color Hunt](https://colorhunt.co), by tag;
- [Coolors](https://coolors.co), trending;
- [Figma's palette pages](https://www.figma.com/color-palettes/);
- [Realtime Colors](https://www.realtimecolors.com);
- [Adobe Color](https://color.adobe.com), Huemint and Happy Hues.

It gathers six to ten candidates from at least two sources. Then `palette.py` does the rest:

- **Reads them from their URLs.** Coolors, Color Hunt and Realtime Colors links carry the colors, so no network is needed.
- **Gives each color a UI role:** ink, paper, primary, secondary, accent.
- **Checks contrast as the app will use it:** body text, a text button, a label on a filled button, an accent icon.
- **Fixes or warns.** It darkens a pastel that can't carry text (same hue, and says from what to what). It warns about the default purple, a red primary that reads as an error, neon, and poster palettes with five loud colors.
- **Ranks them**, putting palettes from real sources ahead of the fallback library.

You get three palettes on a preview sheet, each with a light and an approximate dark mock-up and a Realtime Colors link, plus a recommendation. The one you pick becomes `AppThemeConfig` seeds (`seed`, `secondarySeed`, `tertiarySeed`, `neutralSeed`), so Material derives dark mode, the on-colors and soft containers. Its source URL is recorded in `DESIGN.md`.

```bash
python3 <flutter-modern-ui>/scripts/palette.py https://coolors.co/264653-2a9d8f-e9c46a-f4a261-e76f51 \
    https://colorhunt.co/palette/f9f7f7dbe2ef3f72af112d4e --curated warm food --preview palettes.png
python3 <flutter-modern-ui>/scripts/palette.py <the one you picked> --dart --design-md
```

With no web access, a curated library of 22 palettes covers common subjects; every one passes as it is, and CI builds each into a Flutter theme and checks it in light and dark.

### Drop-in design system (`assets/design_system/`)

No third-party packages. Copy it kit by kit from the project root:

```bash
python3 <flutter-modern-ui>/scripts/copy_design_system.py                 # core kit → lib/core/design_system
python3 <flutter-modern-ui>/scripts/copy_design_system.py --kit extras    # motion, adaptive shell, KPI tiles
python3 <flutter-modern-ui>/scripts/copy_design_system.py --status        # later: what the plugin changed since you copied
python3 <flutter-modern-ui>/scripts/copy_design_system.py --update        # take the fixes to files you haven't edited
```

The copy is yours to edit, so it is never overwritten silently. Each copy records the plugin version and a hash per file in `.flutter-modern-ui.json`; `--status` tells your edits from the plugin's changes, `--diff` shows a file against the current template, and `--update` only touches files you left alone.

The **core** kit is what every app needs (tokens, theme, motion level, palette, cards, pills, `MetaItem`, empty states, skeletons, sheets and pickers, chips, `SaveBar`, messages, `Ltr`); the **extras** add motion, `AdaptiveShell` and `KpiTile` when the app animates, runs on tablets or desktop, or has a dashboard. The script keeps files you've changed, writes the barrel, and in `material_ui` projects (Flutter 3.50+) imports `material_ui` / `cupertino_ui`.

- **Tokens**: spacing, radius roles with a concentric-corner helper, elevation, strokes, opacity, sizes, breakpoints and window size classes, motion durations and M3 curves.
- **`AppThemeConfig`**: seed and scheme variant, font and fallback, **Arabic script** (zero letter-spacing, taller lines), **eye-comfort surfaces** (warm, dimmed, contrast-checked), **filled or outlined inputs**, touch and desktop density, and the **motion level** (`none`, `soft`, `expressive`) that every shared motion piece follows.
- **Context helpers**: `context.isNarrow` (width ÷ text scale < 340: stack paired rows at big fonts), `context.iconSize` (inline icons grow with text), `context.listEndPadding(fab:)` (lists end clear of the navigation bar and the FAB).
- **`AppTheme`**: light and dark, every common component themed, desktop scrollbars and tooltips, checkmarked chips, data tables, predictive-back page transitions.
- **`AppDensity`**: 48 px touch vs 40 px desktop controls, chosen by platform.
- **`AppPalette`**: success / warning / info tones (add your domain tones): a strong color from the seed and a soft container, even for saturated brand seeds; soft and hover shadows.
- **Widgets**: `AppCard` (ink, hover, press scale, raised tiles), `StatusPill` (icon required), `IconBadge`, `EmojiBadge`, `SectionHeader`, `EmptyState`, `Shimmer` / `SkeletonBox` / `ShowAfter`, `Ltr`, `showAppSheet` + `SheetScaffold` (with an inline `error`), `showAppPicker` (pick-one sheet, no footer), `SaveBar` (bottom action inside the safe area), `MetaItem` (icon + muted detail), `AppChoiceChips` (wrapping, with an optional inline label), `AppMessenger` (one message component, `persist: false`, failure helper, **delete with Undo**), `AdaptiveShell`, `ContentWidth`, `KpiTile` / `KpiGrid`.
- **Motion**: `Entrance`, `AnimatedItems` (diffing sliver list/grid that keeps item state), `StateSwitcher`, `SubmitButton`, `AnimatedNumber`, `AppProgressBar`, `ShakeOnChange`, `PopOnChange`, `MiniBarChart` + `NiceScale`.

### Verification harness (`flutter-ui-verify/assets/harness/`)

Copy with `python3 <flutter-ui-verify>/scripts/copy_harness.py` (→ `test/ui/`; it never overwrites your cases), edit only `ui_cases.dart`: every screen in each state, every form in create and edit mode, the app shell with a tab switch and a push, every sheet (`SheetCase.picker` for pick-one sheets), fakes in `setUp`. Then:

```bash
flutter test test/ui                                                              # layout matrix, sheets, contrast, a11y
flutter test test/ui/visual_test.dart test/ui/sheets_test.dart --update-goldens --dart-define=VISUAL=true  # screenshots → test/ui/screenshots/
```

Phones and tablets render under the system bars a device draws (status bar with a camera cutout or the Dynamic Island, navigation bar or home indicator), drawn in the screenshots too, and the layout test fails when text or a tap target sits under them or touches them, at rest or with a list scrolled to its end:

```
[360_light_android_ltr_x1.0 and 23 more] "Save changes" (tap target) is 0 px from the navigation bar (48 px): SafeArea(top: false) around it, plus 8 px or more  ← lib/features/bills/bill_form.dart:120
```

Content under a bar is a defect anywhere; content inside the safe area but closer than 8 px is this plugin's house rule, labeled as such in the failure line, and `UiConfig.systemBarGap` changes it.

While iterating, render less: `--plain-name "layout: <case>"` for one screen, or `--dart-define=QUICK=true` for every screen in five variants instead of the whole matrix. Run the whole matrix before calling a pass done.

**What a green run doesn't tell you.** The system-bar check sees text and tap targets, not images or painted charts; the contrast test checks theme color pairs, and the accessibility test measures text pixels but not icons or text merged into a row; the lint matches patterns and can't follow a value through a variable. `flutter-ui-verify/references/harness.md` › *What the checks do not see* and the docstring of `lint_ui.py` list the gaps. That is why the last step is always opening the screenshots.

Each case also gets a contact sheet (`screenshots/contact_sheets/<case>.png`, every variant side by side), so a pass is reviewed a screen at a time. Two scripts cover what tests can't see:

```bash
python3 <flutter-modern-ui>/scripts/lint_ui.py --diff                                   # raw colors, sizes, spacing, token math, left/right
python3 <flutter-ui-verify>/scripts/check_glyphs.py --font assets/fonts/MyFont-Regular.ttf lib   # symbols the font lacks (₪, ٫, ✓)
```

A layout failure reads:

```
[360_light_android_rtl_x1.3] A RenderFlex overflowed by 13 pixels on the right.  ← lib/features/bills/bill_tile.dart:42
```

### Printed documents (`flutter-ui-verify/assets/pdf/`)

A fixed `pw.Page` drops content that doesn't fit without an error, so the test that builds a PDF stays green while the signatures disappear. Mark the blocks that must survive on paper, copy the PDF harness into `test/pdf/`, list sample cases (typical, empty optional fields, longest content) in `pdf_cases.dart`, then:

```bash
flutter test test/pdf                                          # test/pdf/out/<case>.pdf + block checks
python3 <flutter-ui-verify>/scripts/rasterize_pdf.py test/pdf/out --text   # PNG per page, flags "null"
```

```
test/pdf/out/invoice_ar_longest.pdf (1 page)
  • "signatures" was not painted: the content before it ran past the page, and a fixed pw.Page drops the rest without an error. …
```

**Values on a pre-printed form** (a cheque, a bank slip, a government form) can't be eyeballed: a PNG can't tell 7.6 cm from 7.9 cm. `preprinted-forms.md` and `examples/cheque_pdf.dart` cover:
- positions in cm from the paper's corner;
- the baseline on the printed line, from the font's real metrics;
- shrinking that keeps the baseline still, and start room so a leading «ا» isn't clipped;
- a print call that always carries its paper size, and feed direction;
- system fonts such as Calibri;
- a test sheet with a 10 cm ruler, and a per-printer offset.

The PDF test writes what each value's ink must look like, and `measure_pdf.py` checks it on a 600 dpi raster:

```bash
python3 <flutter-ui-verify>/scripts/measure_pdf.py test/pdf/out                     # baseline, start and end of every value, in cm
python3 <flutter-ui-verify>/scripts/check_glyphs.py --font calibri.ttf --metrics "تحريراً في" --size 11   # ascent, descent, deepest glyph, Arabic seat
```

## Requirements

- Flutter **3.41 or newer** for the Dart templates (`SnackBar.persist`, `AppBarThemeData`, `InputDecorationThemeData`, `TickerMode.valuesOf`, `SizeTransition.alignment`). CI checks them on a pinned release (3.50.0 now; `FLUTTER_VERSION` in `.github/workflows/ci.yml`), both with the `material_ui` package that `flutter create` adds from 3.50 and with `package:flutter/material.dart`. The skills tell Claude how to adapt to older SDKs.
- The scripts need Python 3.9+ (`check_glyphs.py` also needs `pip install fonttools`; `palette.py --preview` draws a PNG with `pip install pillow`, an SVG without it). Searching palette sites uses Claude's web search and fetch, or a browser for the sites that draw their palettes with script; with neither, the curated library still works.
- The printed-document example and its harness need the [`pdf`](https://pub.dev/packages/pdf) package; rasterizing needs Python with PyMuPDF (`pip install pymupdf`) or poppler's `pdftoppm`.
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

/flutter-modern-ui:flutter-ui-verify Check every screen and sheet at 360 px and text scale 1.6, then show me the screenshots.

/flutter-modern-ui:flutter-ui-verify The receipt PDF: render the longest case and the one with no optional fields, then show me the pages.

/flutter-modern-ui:flutter-ui-audit lib/features/orders/ — report first, then fix the high and medium findings.
```

Tips:

- Correct the brief the skill proposes (subject, audience, job, feeling, signature): two minutes there decide more than any later tweak.
- Answer the intake questions (platforms, RTL, the look, emoji, motion) once; they land in `DESIGN.md` and later sessions read them. The look (cards, plain rows or rich) matters most: "basic" in a spec rarely means plain rows. For motion you pick a level (none, soft or expressive) and the places, each shown with a small example.
- Commit `DESIGN.md`. It's how the tenth screen ends up looking like the first.
- The skills change presentation only. Your state management, routing and DI stay as they are.

## What this repo has and hasn't shown

- **Shown:** the templates compile, pass their own harness in both Material modes and are linted by their own linter on every PR; the harness's checks have tests for what they must catch and what they must leave alone; each rule in the changelog traces to an entry in a feedback log from a real app.
- **Field base:** two Arabic apps on Android and Windows. iOS and Cupertino, web, go_router and Riverpod have snippets and a few tests, not field use.
- **Not shown yet:** a published with-and-without-plugin eval baseline. The suite is in `plugins/flutter-modern-ui/evals/` and `CONTRIBUTING.md` says how to run and record it; results aren't committed until someone has run them.
- **The design layer** (identity, UX, screen types, wording) is newer than the engineering layer and has had less use. Treat its advice as defaults to argue with; `DESIGN.md` overrides it.

## Contributing

Issues and PRs welcome, especially real-project feedback: use [`docs/feedback-template.md`](docs/feedback-template.md). Rules for changes are in [CONTRIBUTING.md](CONTRIBUTING.md); CI builds a sandbox app from the templates and runs `flutter analyze`, the UI tests, the PDF checks, the screenshot pass and the page rasterizer on every PR. Changes to what the skills say are measured with the eval suite: `claude plugin eval plugins/flutter-modern-ui` (it runs Claude sessions on your account).

```bash
bash scripts/sandbox.sh --material-ui && cd build/sandbox && flutter analyze && flutter test test/ui test/pdf test/ci
```

## License

MIT © Maen Khdour

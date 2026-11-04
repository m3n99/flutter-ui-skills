# flutter-ui-skills

Claude Code skills that make Claude build **modern, polished Flutter mobile UI** instead of default-looking Material screens.

Out of the box, AI-generated Flutter UI tends to look the same: the stock purple seed, `Card(elevation: 4)`, `fontSize: 15` sprinkled everywhere, random `SizedBox(height: 10)` gaps, a centered spinner for loading, and no empty or error states. This plugin gives Claude a design system, a set of composition rules, and a review loop so the output looks intentional from the first build.

## What's inside

| Skill | What it does |
|---|---|
| `flutter-modern-ui` | Builds or restyles screens. Picks a design direction, sets up tokens + a tuned Material 3 theme (light & dark), composes screens with modern patterns, adds skeleton/empty/error states and motion, then self-reviews against a checklist. |
| `flutter-ui-audit` | Reviews existing screens, reports findings by severity with `file:line`, then applies presentation-only fixes (theme first, then tokens, then screens). |

```
plugins/flutter-modern-ui/skills/
├── flutter-modern-ui/
│   ├── SKILL.md
│   ├── references/
│   │   ├── directions.md       # 6 design directions with concrete token values
│   │   ├── tokens.md           # spacing, radius, type scale, color roles, motion
│   │   ├── theming.md          # ColorScheme.fromSeed, ThemeExtension, component themes, dark mode, Arabic fonts
│   │   ├── layout.md           # screen anatomy, rhythm, hierarchy, responsive, RTL, keyboard
│   │   ├── components.md       # app bars, cards, lists, buttons, inputs, sheets, nav, stats
│   │   ├── motion.md           # durations, curves, switchers, hero, stagger, haptics, reduced motion
│   │   ├── states.md           # skeletons, empty, error, refresh, optimistic updates
│   │   ├── anti-patterns.md    # 27 "looks generic" patterns and their fixes
│   │   └── review-checklist.md
│   └── assets/
│       ├── design_system/      # drop-in Dart: tokens, AppPalette, typography, AppTheme, widgets
│       └── examples/dashboard_screen.dart
└── flutter-ui-audit/
    └── SKILL.md
```

### Drop-in design system (`assets/design_system/`)
- `tokens.dart` — `AppSpace`, `AppRadius`, `AppIconSize`, `AppDurations`, `AppCurves`
- `app_palette.dart` — `ThemeExtension` with success / warning / info (+ containers) and a soft shadow, generated per brightness
- `app_typography.dart` — tuned type scale (tracking, line heights, weights)
- `app_theme.dart` — `AppTheme.light()` / `AppTheme.dark()` with app bar, cards, buttons, inputs, chips, nav bar, sheets, dialogs, snackbars, list tiles, tabs and FAB themed
- `context_ext.dart` — `context.colors`, `context.textStyles`, `context.palette`, `context.reduceMotion`
- `widgets/` — `AppCard`, `Pressable`, `Shimmer` + `SkeletonBox`, `EmptyState`, `SectionHeader`, `StatusPill`, `IconBadge`

No third-party packages required. Targets **Flutter ≥ 3.32 / Dart ≥ 3.8** (`Color.withValues`, `WidgetState`, `CardThemeData`, `Row/Column(spacing:)`); the skill tells Claude how to adapt for older SDKs.

## Install

### As a plugin (recommended)
In Claude Code:
```
/plugin marketplace add m3n99/flutter-ui-skills
/plugin install flutter-modern-ui@flutter-ui-skills
```
Restart Claude Code if the skills don't show up immediately. Update later with `/plugin marketplace update flutter-ui-skills`.

### As plain skills (no plugin system)
Copy the skill folders into your user or project skills directory:
```bash
git clone https://github.com/m3n99/flutter-ui-skills.git
# for all projects
cp -r flutter-ui-skills/plugins/flutter-modern-ui/skills/* ~/.claude/skills/
# or for one project (commit it so your team gets it too)
mkdir -p .claude/skills && cp -r flutter-ui-skills/plugins/flutter-modern-ui/skills/* .claude/skills/
```
Keep both folders side by side: the audit skill reads references from `flutter-modern-ui`.

## Usage

Skills trigger automatically on Flutter UI work. You can also call them directly.

```
Build a transactions screen for our wallet app: list grouped by day, filter chips, search.

/flutter-modern-ui Redesign lib/features/profile/profile_screen.dart in the Bold Contrast direction.

Set up the design system in this project with seed #0F766E and the Inter font, Arabic fallback IBM Plex Sans Arabic.

/flutter-ui-audit lib/features/orders/ — report first, then fix the high and medium findings.
```

Tips:
- Name a direction (*Soft Minimal*, *Bold Contrast*, *Editorial*, *Glass & Depth*, *Playful*, *Enterprise Dense*) or give a brand color; otherwise Claude picks one and tells you.
- If your project already has a theme or design-system package, the skill extends it instead of adding a second one.
- The skills change presentation only. Your state management, routing and DI stay as they are.

## Contributing
Issues and PRs welcome, especially new design directions, component patterns, and before/after screenshots. Keep rules concrete (values, widget names) rather than adjectives.

To test locally before pushing:
```bash
claude plugin validate .
claude --plugin-dir ./plugins/flutter-modern-ui
```

## License
MIT © Maen Khdour

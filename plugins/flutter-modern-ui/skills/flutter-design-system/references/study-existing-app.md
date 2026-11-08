# Studying an existing app

Goal: know exactly what the app's UI is made of today, how far it has drifted, and the smallest set of changes that makes it consistent.

## 1. Inventory

```bash
bash <skill-dir>/scripts/ui_inventory.sh lib            # single app
bash <skill-dir>/scripts/ui_inventory.sh apps/app/lib packages/ui/lib   # monorepo
```

It prints: design-system files, platform folders, l10n languages, hard-coded colors, font sizes, spacing values, radii, elevations and shadows, RTL risks, component usage (cards, buttons, spinners, snackbars/toasts, sheets, dialogs, tables) and motion usage.

Then read, in this order:

1. The theme builder and token files (what the system *says*).
2. Three representative screens: the home/dashboard, the main list, the main form (what the app *does*).
3. Shared widgets folder (what has already been extracted).
4. DESIGN.md / design notes / README UI sections (what was *decided*).

## 2. Write the inventory table

| Area | Defined in system | Actually used | Drift |
|---|---|---|---|
| Spacing | 4, 8, 12, 16, 24 | 4, 6, 8, 10, 12, 14, 16, 18, 20, 24 | 6, 10, 14, 18, 20 off-scale |
| Radius | 12 | 4, 8, 10, 12, 16, 20 | 6 values, no roles |
| Font sizes | text theme | 11, 12, 13, 14, 15, 16, 18, 22 | 13, 15, 22 off-scale |
| Colors | ColorScheme | + 37 raw `Colors.*` / hex in widgets | |
| Cards | `AppCard` | `Card(elevation: 2)` ×9, `Container` + `BoxShadow` ×6 | 3 card styles |
| Loading | — | centered spinner on 7 screens | no skeletons |
| Messages | `CustomToastMessage` | + 4 direct `SnackBar`s | 2 paths |
| Sheets | — | 5 sheets, 4 layouts | no shared anatomy |
| RTL | — | 23 `left/right` APIs | breaks in Arabic |

Healthy targets: spacing only from the scale; ≤ 5 radius values with named roles; font sizes only from the type scale; zero raw colors outside theme files; one card style per card type; one message path; one sheet anatomy.

## 3. Normalize: found → token

Propose a mapping that snaps every found value to the nearest token, and show it before applying when the visual change is noticeable:

| Found | Token | Note |
|---|---|---|
| padding 10 | `AppSpace.sm` (12) | +2 px |
| padding 14, 15 | `AppSpace.md` (16) | |
| gap 6 | `AppSpace.xs` (8) | |
| radius 10 | `AppRadius.card` (12) | Enterprise Dense |
| fontSize 15 | `bodyLarge` (16) / `titleSmall` (14) by role | decide per use |
| `Colors.red` for overdue | `palette.overdue` tone | new domain tone |
| `Colors.grey[600]` text | `onSurfaceVariant` | |

Ambiguous values (a 13 px label that might be bodySmall or labelMedium) are decided by role, not by size.

## 4. Extract components

Extract a shared widget only when a structure repeats (two or more times) or the pattern is easy to get wrong:

- card types (content, group, row, KPI);
- status mapping (one extension per status enum);
- sheet anatomy (`SheetScaffold`), filter sheets;
- message component with `persist: false`, failure helper and Undo deletes;
- skeletons per list type; empty/error states;
- animated lists keyed by id.

Name them in the project's style and put them where its shared widgets live.

## 5. Document

Write DESIGN.md (template `assets/templates/DESIGN.md`) from the system as it now stands, including the deliberate deviations the team wants to keep. Every rule must be checkable against a screen or the source.

## 6. Migrate

- Open `UI_PASS.md` (template) with the audit, then migrate in passes: foundation (tokens, theme) → shared components → screens, one concern per change.
- Screenshot before and after each screen (flutter-ui-verify). Visual changes should be intentional and visible in the shots; anything unexpected is a regression.
- Keep tests green after every pass; run the layout matrix at the end.

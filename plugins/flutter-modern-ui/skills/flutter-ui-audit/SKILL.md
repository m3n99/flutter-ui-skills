---
name: flutter-ui-audit
description: Audit existing Flutter screens or widgets for design quality and fix what makes them look dated or generic. Use when the user asks to review, polish, modernize, "make prettier", or critique Flutter UI, or shares a screen file / screenshot and asks what's wrong with it.
---

# Flutter UI Audit

Review existing Flutter UI against the `flutter-modern-ui` standards, report findings, then fix them with minimal, presentation-only changes.

The standards live in the sibling skill. Read these before auditing:
- `../flutter-modern-ui/references/anti-patterns.md`
- `../flutter-modern-ui/references/review-checklist.md`
- `../flutter-modern-ui/references/tokens.md` (for the correct replacement values)

## Workflow

### 1. Scope
- If the user named files or a screen, audit those. Otherwise ask which screen(s), or start with the main entry screens (home/dashboard, primary list, primary form).
- Read the project's theme setup first (`MaterialApp` theme, any `ThemeData`, `ThemeExtension`, token or design-system folder). Many screen-level problems are really theme-level problems; fix them once in the theme.
- If a screenshot is provided, use it as the primary evidence for visual issues and the code for root causes.

### 2. Audit
Go through the checklist and anti-pattern table. For every finding record:
- **Where**: `file.dart:line` (or the widget name).
- **What**: the concrete problem ("card uses elevation 4 + black26 shadow").
- **Why it matters**: one short clause (hierarchy, dark mode, RTL, overflow, consistency).
- **Fix**: the exact replacement (token/role/widget).

Severity:
- **High** — broken or inaccessible: overflow, unreadable contrast, broken dark mode or RTL, tiny tap targets, missing error/empty states.
- **Medium** — clearly dated/generic: default seed or tint, heavy shadows, no hierarchy, off-grid spacing, multiple primary buttons, spinner-only loading.
- **Low** — polish: icon style mixing, missing press feedback, missing tabular figures, minor alignment.

### 3. Report
Lead with a short verdict (2–3 sentences: overall state and the 3 changes with the biggest visual payoff). Then a findings table grouped by severity. Keep it scannable; no essays.

### 4. Fix
Unless the user asked for a report only, apply fixes in this order:
1. **Theme level** (one change, many screens): seed/variant, surface tint removal, component themes, typography scale, semantic colors.
2. **Tokens**: replace raw numbers and colors in the audited files with tokens/roles. Add `tokens.dart` / `AppPalette` from `../flutter-modern-ui/assets/design_system/` only if the project has nothing equivalent.
3. **Structure-preserving screen fixes**: hierarchy, spacing rhythm, grouping, states, press feedback, overflow and RTL fixes.

Rules while fixing:
- Change presentation only. Keep the widget tree shape, state management, routing, DI, naming and file layout unless the user asks for a refactor.
- Edit the code that exists; don't introduce wrapper layers, extra lists or new abstractions just to apply a style.
- Keep diffs reviewable: one concern per edit where possible.
- Don't add packages without asking.
- Run `flutter analyze` on changed files if Flutter is available.

### 5. Close
Summarize what changed in 3–5 bullets (theme vs screen), and list any findings intentionally left for later with the reason.

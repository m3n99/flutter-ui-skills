---
name: flutter-ui-audit
description: Audit existing Flutter screens for design quality, identity, UX flow, wording, consistency, platform fit, RTL, accessibility and motion, then fix them with presentation-only changes verified by screenshots. Use whenever the user asks to review, check, polish, modernize, "make prettier", QA or critique Flutter UI or UX, says an app feels generic or clumsy to use, or pastes a widget, a screen file or a screenshot and asks whether anything is wrong with it, even as a quick question: load this skill first instead of reviewing from memory.
---

# Flutter UI Audit

Review existing UI against the `flutter-modern-ui` standards, report findings with evidence, then fix them in the project's own style, and prove the result with before/after screenshots.

Standards (read before auditing):
- `../flutter-modern-ui/references/anti-patterns.md`
- `../flutter-modern-ui/references/review-checklist.md`
- `../flutter-modern-ui/references/tokens.md` (replacement values)
- `../flutter-modern-ui/references/identity.md`, `ux.md`, `writing.md` (does it belong to this app, does the flow serve the task, do the words say what happens)
- the project's `DESIGN.md`, if it exists: it overrides the defaults.

## Workflow

### 1. Study and scope

- Run Step 0 of the hub skill (`../flutter-modern-ui/references/discovery.md`): find and read the design system, DESIGN.md, the message component, the state flow; baseline `flutter analyze` and `flutter test`.
- Run the inventory: `bash ../flutter-design-system/scripts/ui_inventory.sh lib` (hard-coded colors, font sizes, spacing, radii, RTL risks, spinners, toasts, motion).
- Scope: the screens the user named; otherwise the main entry screens (home/dashboard, main list, main form) plus every sheet they open.
- Ask the intake questions the project doesn't already answer (platforms, RTL, emoji, motion) when they change what counts as a finding.

### 2. Capture the "before"

If the harness can run, set it up (`../flutter-ui-verify/SKILL.md`), run the layout matrix and sheet test, and render screenshots. View them. Screenshots the user shared are evidence too. If the screens print documents, render the sample PDFs and rasterize them too (`../flutter-ui-verify/references/printed-documents.md`).

### 3. Audit

Go through the checklist and anti-patterns for each screen. Record each finding as:

- **Where**: `file.dart:line` or widget name, and the screenshot if visible there.
- **What**: the concrete problem ("card uses `elevation: 4` + `Colors.black26` shadow").
- **Why it matters**: one clause (hierarchy, dark mode, RTL, overflow, consistency, accessibility).
- **Fix**: the exact replacement (token, role, shared widget, pattern).

Areas: identity (a brief and a signature, or defaults that would fit any app) · flow (the task per screen, taps for the frequent ones, where the primary action sits, what gets retyped or lost) · words (button labels, one name per thing, empty and error text) · system use · hierarchy · spacing · shapes (nesting, card types) · status & selection (never color alone) · states (skeletons, empty, error) · messages (one component, copy, Undo, `persist: false`) · sheets (shared anatomy, footer order) · forms (labels, keyboard, save bar) · platforms (touch targets, desktop pointer affordances, breakpoints) · RTL · accessibility (contrast, semantics, text scale) · motion (purpose, tokens, reduced motion, list state).

Severity:
- **High**: broken or inaccessible: overflow, unreadable contrast, broken dark mode or RTL, tiny tap targets, missing error/empty states, primary action hidden by the keyboard, double submits, deletes without confirm or Undo.
- **Medium**: dated, generic or inconsistent: default seed and font with no brief behind them, a home screen that is a menu or a grid of numbers with no next step, the frequent task buried, placeholder wording ("Submit", "Success", "No data"), heavy shadows, no hierarchy, off-grid spacing, several primary buttons, spinner-only loading, sheets with different layouts, generic messages, status by color.
- **Low**: polish: icon style mixing, missing press feedback, missing tabular figures, 2 px misalignment.

### 4. Report

Lead with a 2–3 sentence verdict naming the three changes with the biggest payoff. Then the findings table grouped by severity. Open `UI_PASS.md` (template in `../flutter-design-system/assets/templates/`) with the findings as a checklist so the work can resume across sessions.

### 5. Fix (unless the user asked for a report only)

Order:
0. **The brief**, if the app has none: write the five lines from what the app is and get them confirmed; they decide the theme-level fixes.
1. **Theme level** (one change, many screens): seed/variant, tints, component themes, density by platform, typography (Arabic tracking), semantic and domain tones.
2. **Tokens**: replace raw values in the audited files; add missing tokens to the project's existing token file.
3. **Shared patterns** the findings call for, in the project's naming: status mapping, sheet anatomy, message component with Undo, skeletons, animated lists.
4. **Screens**: hierarchy, spacing, grouping, states, overflow and RTL fixes.

While fixing:
- Presentation only: keep the widget tree shape, state management, routing, DI, naming and file layout unless the user asks for a refactor.
- Edit the code that exists; no wrapper layers or extra lists just to apply a style.
- One concern per change; tick `UI_PASS.md` as items land.
- No new packages without asking.

### 6. Verify

Re-run `flutter analyze`, the tests, the layout matrix and the sheet test; re-render the screenshots and compare before/after for every finding. When the pass touches more than three screens, hand the after-screenshots to the `flutter-ui-reviewer` agent.

### 7. Close

- Update DESIGN.md with decisions and new patterns.
- Summarize in 3–5 bullets (theme vs screens), list the screenshots that show the change, and list findings deliberately left open with the reason.

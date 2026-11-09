# UI pass — {scope}

Resume from the first unticked item. The rules are in DESIGN.md.

**Status:** {in progress / done (date)}
**In progress:** {item}
**Next up:** {item}

## Audit ({date})

- Framework: Flutter {version}, Material 3, {state management} ({access pattern}), {router}.
- Targets: {Android (touch), Windows (mouse)}. {RTL Arabic only / LTR + RTL}. Light + dark.
- Design system: {path} ({what it contains}). Extend it; no second system.
- Messages: {one component / several paths}.
- Baseline: `flutter analyze` {clean / N issues}, `flutter test` {N/N pass}.

### Inventory

Screens: {list with their main parts}.
Sheets and dialogs: {list}.
Hard-coded values: {counts from ui_inventory.sh}.

### Intake answers

- Platforms: {…} · RTL: {…} · Emoji: {…} · Motion: {…}

## Checklist

### 1. Foundation
- [ ] 1.1 Tokens: {missing tokens to add to the existing file}
- [ ] 1.2 Replace magic numbers with tokens in {files}

### 2. Dimensions and layout
- [ ] 2.1 Touch targets ≥ 48 on touch platforms
- [ ] 2.2 Layout test covers {screens and sheets} at 360 × 1.3

### 3. Nested shapes
- [ ] 3.1 {group-card rows: radius 12 − 8 = 4}

### 4. Sheets and filters
- [ ] 4.1 Shared sheet anatomy (`showAppSheet` + `SheetScaffold`)
- [ ] 4.2 {sheet} → SheetScaffold

### 5. Motion
- [ ] 5.1 {AnimatedItems on lists}
- [ ] 5.2 {charts / progress from previous values}

### 6. Messages
- [ ] 6.1 One component: icon + text, `persist: false`, failure helper
- [ ] 6.2 Messages name the thing
- [ ] 6.3 Delete with Undo
- [ ] 6.4 Submit buttons can't double-submit

### 7. Verification and docs
- [ ] 7.1 Screenshots reviewed (light, dark, 1.3, RTL, desktop)
- [ ] 7.1b Printed documents: sample PDFs (typical, empty optional fields, longest) pass the block checks; every page opened
- [ ] 7.2 DESIGN.md updated
- [ ] 7.3 `flutter analyze` clean, tests pass

## Done notes

- {what changed, new shared widgets, tests added}

## Decisions

- {decision and why}

## Open decisions

- {question for the user, with the options}

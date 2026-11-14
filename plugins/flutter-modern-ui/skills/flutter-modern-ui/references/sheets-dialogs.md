# Bottom sheets, filter sheets and dialogs

Every sheet uses `showAppSheet` + `SheetScaffold` (`assets/design_system/widgets/app_sheet.dart`), so filters, payments, exports and pickers all look and behave the same. Reference: the filter sheet in `assets/examples/records_screen.dart`.

## Which container

| Need | Use |
|---|---|
| Choose, filter, short input (1–6 fields), share/export options | Sheet (`showAppSheet`): bottom sheet < 600 px, 560 px dialog wider |
| Confirm one action | `AlertDialog` (420 px) |
| Long form, multi-step, anything over ~6 fields | Full-screen route (`fullscreenDialog: true`) on phones; large dialog or pane on desktop |
| Quick choice from a list (sort, account, language) | Pick-one sheet (`showAppPicker`): one tap chooses and closes; or a `MenuAnchor` on desktop |
| Persistent condition (offline, read-only mode) | `MaterialBanner` / inline banner, not a dialog |

Prefer sheets over dialogs for anything with input or more than two actions.

## Anatomy (top to bottom)

1. **Drag handle**: sheets only, from the theme.
2. **Header**: title in headlineSmall at the start, close ✕ (`IconButton` with the localized close tooltip) at the end. Padding 24 start, 8 end.
3. **Body**: scrolls when long. Padding 24 sides, 8 top, 24 bottom. Sections are `SheetSection`s (label in labelLarge / `onSurfaceVariant`, 8 px above its content), 24 apart.
4. **Footer**: sticky, never scrolls. Hairline top border, inside `SafeArea(top: false)`, padding 24 × 12. Pick-one sheets have none: the tap on an option is the action.

## Footer buttons: the same order in every sheet

- **Start side: secondary** (`OutlinedButton` or `TextButton`), **as wide as its label**.
- **End side: primary** (`FilledButton` / `SubmitButton`), **fills the rest**.
- In RTL the primary therefore sits on the left. One filled button per sheet.
- Why not a 1 : 2 split: fixed splits truncate longer labels (Arabic "مسح عوامل التصفية" truncates at 360 px). If a secondary label is long, shorten it ("Clear all" / "مسح الكل").

| Sheet | Secondary | Primary |
|---|---|---|
| Filters | Clear all (clears the choices in the sheet; disabled with nothing to clear) | Apply, or Apply (n) with n active filters |
| Form / payment | Cancel | Save (spinner while saving) |
| Export (desktop) | Cancel | Export |
| Export (phone) | Share | Save to files (cancel is the header ✕) |

## Filter sheets

- Sections: Status (multi-select chips), Sort by (single choice), Date range, etc.
- Chips 8 px apart both ways; all the same height; selected = check + fill.
- "Clear all" resets the choices **in the sheet** only; "Apply" makes them stick. Both behave like every other sheet (no apply-and-close on reset).
- Show the active count on Apply ("Apply (3)") and on the screen's filter button badge.
- Results animate when the sheet closes (`AnimatedItems`).

## Pick-one sheets

- One choice that applies at once (sort order, account, language): `showAppPicker`. Options are `ListTile`s with an optional leading icon; the current one shows a check and the selected colors (never color alone); a tap chooses and closes. No footer, no Apply. Reference: the sort sheet in `assets/examples/records_screen.dart`.
- A choice that's part of something larger (a filter sheet, a form) stays as chips or radio tiles in a `SheetScaffold` with a primary action.
- More than ~7 options: a search field on top; more than ~20: a full-screen picker.
- The harness checks them as `SheetCase.picker(...)`: options on screen with real tap targets, and a tap closes the sheet.

## Keyboard

- As a bottom sheet, the content is padded by the keyboard inset (`MediaQuery.viewInsetsOf(context).bottom`), so the focused field and the footer stay visible. `SheetScaffold` does this.
- Dialogs move themselves (Dialog adds the inset to its padding); don't pad them again.
- `isScrollControlled: true` and `useSafeArea: true` on modal bottom sheets (in `showAppSheet`).
- The sheet test checks that the primary action stays above a 300 px keyboard at 360 px and text scale 1.3.

## Dialog details

- `clipBehavior: Clip.antiAlias` so the footer's border and fill don't paint past the rounded corners.
- Max widths: confirm 420, sheet-as-dialog 560, large form 1000.
- `barrierDismissible: true` for choices; `false` while saving.
- Title states the action ("Delete INV-1042?"); the body states the consequence in one sentence ("The invoice for Kinetic Labs will be removed. You can undo this for a few seconds."); actions: `TextButton('Cancel')` then the destructive `FilledButton` styled with `error`.
- Typed confirmation for irreversible bulk actions (delete all data): the user types a shown word; the confirm button enables only when it matches.

## Motion

- Default sheet and dialog transitions are fine; keep them (they respect platform conventions).
- `showModalBottomSheet(sheetAnimationStyle: AnimationStyle(duration: …, reverseDuration: …))` to tune durations if needed (tokens only).
- Content inside a sheet that changes (step 1 → step 2) cross-fades with `StateSwitcher`, and the sheet height animates with `AnimatedSize`.

# Forms

Reference: `assets/examples/record_form_screen.dart`.

## Field anatomy

- **Label above the field** (titleSmall), field below, helper or error text under it. Floating labels read as dated in most modern designs.
- **Optional fields say so in the label**: "Email (optional)", «البريد (اختياري)»; required fields carry no mark. One helper (`optional(label)`) keeps the wording the same everywhere.
- Field gap 16, section gap 16–24 (sections as `AppCard`s with a titleMedium heading, or `SheetSection`s inside sheets).
- Always set `keyboardType`, `textInputAction` (next / done / search), `autofillHints`, `textCapitalization` for names and sentences, and `obscureText` + a visibility toggle for passwords.
- Width: forms cap at 640 px (`ContentWidth.horizontalPadding(width, maxWidth: AppSize.formMaxWidth)`); on wide screens two-column field grids (12 px gaps) for short fields only.

## Input styles

- `InputStyle.filled`: tinted fill, no border until focus. Light consumer forms.
- `InputStyle.outlined`: card-colored fill with an `outline` border at rest. Dense data entry, desktop, and warm low-contrast palettes, where filled fields lose their edges.
- Focus: 1.5 px `primary`. Error: 1 px `error`, 1.5 px focused.

## Validation

- Validate on submit, then live after the first submit (`AutovalidateMode.onUserInteraction` once `_submitted`). Never flag a field red while the user types its first character.
- Error text says how to fix it: "Enter an amount above zero.", not "Invalid".
- On a failed submit: scroll to / focus the first invalid field, and shake the submit button (`ShakeOnChange(trigger: failedSubmits)`), with the error text carrying the meaning.
- **Warnings are not errors.** For unusual-but-valid input (a large amount, a date far in the past), show helper text in the palette's warning color with words that say it's a check ("Larger than usual. Double-check before sending."). The user can still save.

## Money

- Store minor units (`int` cents/fils/agorot), never `double`.
- Input: `keyboardType: TextInputType.numberWithOptions(decimal: true)`, an input formatter that:
  - normalizes Arabic-Indic `٠١٢٣٤٥٦٧٨٩` and Persian `۰۱۲۳۴۵۶۷۸۹` digits to `0-9`;
  - accepts one decimal separator (`.`, `,` or Arabic `٫`) and at most the currency's decimals;
  - drops everything else (`MoneyInputFormatter` in the example).
- Display: `intl` `NumberFormat.currency(locale:, symbol:)` with thousands separators and the locale's currency position; tabular figures; inside `Ltr` in RTL layouts.
- **Several currencies are never added up.** Totals show one line per currency ("₪ 12,400 · $ 3,150"), each formatted on its own; a single number would be wrong for every currency in it.
- **Amount fields in RTL**: the field is LTR (`textDirection: TextDirection.ltr`), so its own `start` is the left even on an RTL screen. The digits then sit at the far end from a currency prefix, or glued to a suffix (`₪2500`). Align them to the reading start: `textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.end : TextAlign.start`, and keep a space in `prefixText` / `suffixText`. Check the font has the currency glyph (`rtl-arabic.md` › Arabic typography).
- Decide the digit style once (Western `0-9` vs Arabic-Indic) and record it in DESIGN.md; many Arabic apps in the Levant and Gulf use Western digits.
- Totals and balances that update live: `AnimatedNumber`.

## Dates

- `showDatePicker` / `showDateRangePicker` with the app locale; `DatePickerEntryMode.input` is faster on desktop.
- The field is a read-only `TextFormField` (`readOnly: true`, `onTap: pick`, `enableInteractiveSelection: false`, `mouseCursor: SystemMouseCursors.click`) with a calendar suffix icon.
- Show a live summary in the helper text ("Due in 14 days").
- Format consistently (`dd/MM/yyyy` or the locale's pattern via `intl`); tabular; `Ltr` in RTL.
- Phones: if a row holds date + amount and truncates at 360 px, stack them (see Editable rows).

## Long forms

1. Body is a `Column`: `Expanded(Form(ListView(…)))` then the **save bar as the last child**. The Scaffold resizes the body above the keyboard, so the bar stays visible.
2. **Don't** put the save bar in `Scaffold.bottomNavigationBar`: the soft keyboard covers it.
3. **Don't** put an `Align` without `heightFactor: 1` inside the bar: in an unbounded-height slot it expands to the full screen and hides the form.
4. Save bar: surface color, hairline top border, `SafeArea(top: false)`, 12 px vertical padding, full-width `SubmitButton`.
5. Sections as cards with a heading; a live summary card (totals, counts) where it helps.
6. `keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`.
7. Unsaved changes: `PopScope(canPop: !dirty, onPopInvokedWithResult: …)` → "Discard changes?" dialog.
8. Desktop: Ctrl/⌘+S saves, Esc asks to discard, Tab order follows the visual order.

## Create and edit

- One screen for both: `initial` (null = create), with a title and button that say which ("Edit INV-1041", "Save changes"). `assets/examples/record_form_screen.dart`.
- **Fill controllers where they're created**, `late final _name = TextEditingController(text: widget.initial?.name)`, or in `initState`. When the data arrives later (a bloc state, a provider), fill them in a listener (`BlocListener`, `ref.listen`, a post-frame callback), **never in `build`**: setting `controller.text` there notifies the field during the build ("setState() or markNeedsBuild() called during build"), and only the pre-filled edit form crashes.
- Edit mode keeps existing values usable: a past due date stays pickable (`firstDate` no later than the current value), an archived category still shows.
- Test both: a create case and an edit case for every form (`flutter-ui-verify`).

## Submit

- `SubmitButton(onPressed: _save)`: spinner while the Future runs, keeps its width, ignores a second press. Or `busy: state.status == Status.saving` when the state layer drives it.
- On success: close the form (or show the check with `successFeedback: true` when the screen stays), and show a message that names the thing ("Created INV-1043 for Blue Harbor Café").
- On failure: keep the input, show what failed and what to do (`messages.md`).

## Autocomplete (especially in RTL)

- `RawAutocomplete` / `Autocomplete` with a custom `optionsViewBuilder`:
  - `Align(alignment: AlignmentDirectional.topStart)` so the overlay starts at the field's start edge in RTL;
  - `ConstrainedBox(maxWidth: fieldWidth, maxHeight: 280)`, otherwise it spans the screen;
  - `Material(elevation: AppElevation.overlay, borderRadius: …)` with option tiles inset 4 px (radius `concentric(menuRadius, 4)`).
- Filling the controller programmatically (edit form opening with a value) triggers `optionsBuilder`. Guard database queries with `if (!focusNode.hasFocus) return const [];` and debounce typing (250 ms).
- Highlight the matched part of each option (bold span); show "No matches" as a single disabled row.

## Editable rows (line items, installments)

- Compact (< 600) or `context.isNarrow`: two lines per row: label on the first line; date | amount (3 : 2) on the second. A one-line row truncates `dd/MM/yyyy` at 360 px. At big font sizes, one field per row.
- From 600 px: one line per row.
- Add row: a `TextButton.icon` at the end of the list; new rows animate in (`AnimatedItems` or `AnimatedSize`) and take focus.
- Remove row: icon button with a tooltip; no confirm for empty rows, Undo for filled ones.

## Settings pages

- Sections as cards (`FormSection` pattern) with a heading; related toggles grouped.
- Toggles (`Switch.adaptive`) apply instantly; no save button for them.
- Text settings save through one pinned bar that appears only when something is dirty ("Save" + "Discard").
- Destructive actions last, in their own section, `error` color.
- "Delete everything" uses typed confirmation (the user types a word shown in the dialog), with no Undo.
- Show the app version and data location (desktop) at the bottom in bodySmall.

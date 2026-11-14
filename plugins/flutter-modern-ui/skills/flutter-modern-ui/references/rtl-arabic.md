# RTL and Arabic

Applies when the app uses Arabic, Hebrew, Persian/Farsi or Urdu, alone or with LTR languages. Take it into account from the first widget; retrofitting RTL costs far more.

## Layout

- **Directional APIs only**: `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `BorderRadiusDirectional`, `TextAlign.start/end`, `CrossAxisAlignment.start/end`. Never `left` / `right`, `EdgeInsets.only(left:)`, `Alignment.centerLeft`, `TextAlign.left`.
- Rows, Wraps and ListViews mirror automatically in RTL; don't reverse children by hand.
- **Icons that point** mirror: back, forward, chevrons, arrows, send, reply, undo/redo, list bullets, "open in new". Material's directional icons (`Icons.arrow_back`, `Icons.chevron_left`, `Icons.chevron_right`) mirror on their own (`matchTextDirection` on the `IconData`); for custom ones use `Directionality`-aware logic or `Transform.flip(flipX: isRtl)`.
- **Don't swap them by direction yourself.** A month switcher uses `Icons.chevron_left` for "previous" and `Icons.chevron_right` for "next" in every language: in RTL they already point the other way. Picking `chevron_right` for "previous" when RTL flips the arrow twice. When unsure, check the `IconData` source for `matchTextDirection: true` (custom icon fonts usually don't set it).
- **Icons that don't mirror**: logos, media controls (play, fast-forward), checkmarks, clocks, search, settings, charts' value glyphs.
- **Footer button order**: "start" is on the right, so the secondary button sits right and the primary left (`SheetScaffold` handles it).
- Progress bars and sliders fill from the right (`AppProgressBar` aligns to `centerStart`).
- Swipe directions flip: `DismissDirection.startToEnd` / `endToStart`.

## Numbers, dates, phones, IDs, amounts

They stay left-to-right inside RTL text.

- In widgets: wrap the smallest widget holding the value in `Ltr` (a `Directionality(ltr)`), or wrap substrings in Unicode isolates with `ltr()` (U+2066 … U+2069): `'تستحق ${ltr('07/12/2026')}'`. Both work in Flutter text.
- In text fields that hold numbers (amount, phone, IBAN): `textDirection: TextDirection.ltr`. That field's `start` is then the left, even on an RTL screen: an amount sits at the far end from a currency prefix, or glued to a suffix (`₪2500`). Align it to the reading start: `textAlign: Directionality.of(context) == TextDirection.rtl ? TextAlign.end : TextAlign.start` (`forms.md` › Money).
- Without this, `0599-123456` can render as `123456-0599` and ranges like `5-10` reorder.
- Inside `Ltr`, "start" means left again: wrap the value, not the whole row.

## Arabic typography

- **Letter-spacing 0** on every role (`AppScript.arabic`). Tracking breaks the joins between letters.
- **Taller line heights**: body ~1.6, titles ~1.45 (built into `AppScript.arabic`).
- Use a font with real Arabic glyphs: IBM Plex Sans Arabic, Noto Sans Arabic, Noto Kufi Arabic, Cairo, Tajawal, Readex Pro; Noto Naskh Arabic / Amiri for editorial reading. Check the weights you use exist.
- Mixed scripts: pick an Arabic font whose Latin matches (IBM Plex Sans Arabic includes Latin), or set `fontFamilyFallback`.
- **Tabular digits**: check the font has `tnum` or equal-width digits (IBM Plex Sans Arabic has no `tnum`, but its 0–9 are all the same width).
- **Glyph coverage, not just letters.** Check the font has every symbol the app shows: currency signs, `٫` `٬` separators, `✓`, arrows. Tajawal has none of `₪ ٫ ٬ ✓`. A missing glyph falls back to some system font (another weight and size) or an empty box, and only a screenshot shows it. Run `python3 ../flutter-ui-verify/scripts/check_glyphs.py --font <each weight's .ttf> --chars "<symbols intl adds at run time>" lib`, then add a font that has them to `fontFamilyFallback` (IBM Plex Sans Arabic has all of these). Printed documents need the same fallback in the PDF theme.
- No uppercase, no small caps, no italics for emphasis in Arabic; use weight or color.
- Arabic punctuation: `،` comma, `؛` semicolon, `؟` question mark.
- Digits: decide Western (0-9) vs Arabic-Indic (٠-٩) once, by audience, and record it in DESIGN.md. `intl` formats per locale; accept both on input (`MoneyInputFormatter` normalizes).

## Localization

- Never hard-code user-visible strings when the project localizes. ARB files + `gen-l10n`, or `intl_utils` (regenerate with `dart pub global run intl_utils:generate`).
- **Arabic has six plural forms** (zero, one, two, few, many, other). Use ICU plurals in ARB: `{count, plural, =0{لا توجد فواتير} =1{فاتورة واحدة} =2{فاتورتان} few{{count} فواتير} many{{count} فاتورة} other{{count} فاتورة}}`.
- Arabic strings are often 20–40 % longer or shorter than English; test both.
- Date formats from `intl` (`DateFormat.yMMMd('ar')`), not hand-built strings.

## Charts

- Most chart packages (fl_chart) lay out left to right regardless of direction: mirror the x index (`x = count - 1 - i`) so time reads right to left, and put the value axis on the reading-start side (right).
- Legends and tooltips align to start.
- Row-based custom charts (`MiniBarChart`) mirror automatically.

## Printing and PDF (`pdf` / `printing` packages)

- `pdf` 3.x shapes Arabic correctly (joining, lam-alef, bold) when you embed a TTF with Arabic glyphs (`pw.Font.ttf(await rootBundle.load(...))`) and set `pw.TextDirection.rtl` on the page or `pw.Directionality`.
- **Unicode isolates do not work in `pdf`**: U+2066/U+2069 render as boxes and nothing is reordered, so phones come out reversed. Put each LTR run (phone, date, amount, ID) in its own `pw.Text` inside `pw.Directionality(textDirection: pw.TextDirection.ltr)`, and lay the parts out with a `pw.Row`.
- Use the same font family in the PDF as in the app; a paper-colored background token if the app has one.
- **A fixed `pw.Page` clips overflow without an error.** A `pw.Column` that runs past the page stops there: the blocks after that point are never painted, and the test that builds the PDF stays green. Three entries in a payment box were enough to drop a bill's signature row. Give every block that grows a **line budget** the form enforces (rows: show the newest n − 1 and one summary row; text: `maxLength`), or use `pw.MultiPage` when the document may legitimately run long (headers and footers repeat, signatures end the last page). Sample data must include the **longest case** the forms allow, and the review must confirm the bottom of the page (signatures, footer) is still there.
- **Overlays placed at a fractional `Alignment`** (a stamp at `pw.Alignment(0.6, 0.7)` in a page-level `pw.Stack`) stay put while the content moves: a taller header landed the stamp on «تحريراً في». Anchor an overlay inside the block it belongs to (a `pw.Stack` in the signature slot, `pw.PositionedDirectional`), and re-check overlays after any header change.
- `maxLines` in `pdf` truncates without an ellipsis: cap the input to what the printed box holds.
- Empty optional fields leave out the whole row: no bare label, no `null`.
- Check and look at every document: `../flutter-ui-verify/references/printed-documents.md` (sample PDFs, block checks, rasterize, review). Reference document: `assets/examples/invoice_pdf.dart`.

## Testing

- Add `TextDirection.rtl` to `uiConfig.directions` (the layout test then covers RTL at 360 / 1000 / 1366 × 1.0 / 1.3 / 1.6).
- Screenshot the main screens in RTL at 360 px and text scale 1.3.
- Mixed-language apps: test both directions; no hard-coded `TextDirection.rtl` outside number helpers.
- Grep for leftovers: `rg -n "EdgeInsets\.only\((left|right)|Alignment\.(centerLeft|centerRight|topLeft|topRight)|TextAlign\.(left|right)|Positioned\((left|right)" lib`.

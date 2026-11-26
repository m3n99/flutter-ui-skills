# Pre-printed forms (cheques, bank slips, government forms)

A pre-printed form already has its lines, boxes and labels on the paper. The app prints only the values, and each value has one right spot, measured with a ruler. Everything in `printed-documents.md` still applies, but a form adds traps that a flowing document never meets, and most of them only show on paper. Reference implementation: `../../flutter-modern-ui/assets/examples/cheque_pdf.dart`, with its checks in the repo's `ci/cheque_pdf_test.dart`.

The loop: **measure the paper → constants in cm → values placed by baseline → sample PDFs with measured expectations → `measure_pdf.py` → print once, check the scale, check on every printer.**

## 1. Positions are constants, in cm, from the paper's corner

- One class holds every position, in cm from the paper's **top-left corner**, named after what was measured (`payeeLine`, `amountBoxRight`, `currencyLabelEnd`). Nothing is placed relative to other content: on a form, nothing flows.
- The page **is** the paper: `PdfPageFormat(width * cm, height * cm, marginAll: 0)`. One `pw.Positioned` per value in a `pw.Stack` of the paper's size.
- The preview is **the same PDF plus guides** (the form's lines and labels in grey), so the preview can't drift from the print.
- Give every value at least **0.2–0.3 cm** from the form's own printed text. Printers place a page a millimetre or two off; a 0.1 cm gap is eaten by that.
- A value next to a printed label (the amount beside a printed currency code in its box) is **anchored away from the label**, e.g. right-aligned when the label is on the left, so spare room goes on the label's side.

## 2. Text sits on its line by its baseline

The rule: **the baseline is on the printed line, and tails go under it**, as in handwriting.

- Don't anchor the deepest glyph above the line. In Arabic the deepest glyph is the tail of «ي» (0.44 em under the baseline in IBM Plex Sans Arabic), so every word without that tail floats 0.44 × size above the line: 0.17 cm at 11 pt, 0.20 cm at 13 pt. People see that on paper, and the gap grows with the size, so no fixed clearance fixes it.
- The pdf package lays a line of text out in a box `(ascent + descent) × size` tall, with the baseline one ascent below its top. Read ascent and descent from the font's `hhea` table (`TtfParser(data).ascent / unitsPerEm` in Dart; `check_glyphs.py --font <file> --metrics` prints them, with the deepest glyph of any text you give it). Then `top = line − ascent × size`.
- **Shrinking a long value must keep the baseline still.** `pw.FittedBox(fit: BoxFit.scaleDown, alignment: pw.Alignment(±1, 2·descent/(ascent+descent) − 1))`. The pdf package's y axis points up, so −1 is the bottom; with `bottomRight`, a shrunk line floats up off its line.
- **The pdf package measures some Arabic runs narrower than it draws them.** Right-aligned Arabic spills past its start edge, and a `FittedBox` clips that spill, so a leading «ا» disappears silently: «ادفعوا» printed as «دفعوا», «اثنا عشر» as «ثنا عشر». It depends on the text: other strings print whole. Keep room on the start side inside the clipped box: about 0.3 em, a `pw.Padding` on the start side of the text inside the `FittedBox`. A plain `pw.Align` doesn't clip, but its overhang still reaches past the box: end fixed captions about 0.12 cm short of their line.
- Sample strings must include values that **start with a bare «ا»** («اثنا عشر», «ادفعوا»).

### A system font (Calibri, Arial, Tahoma)

When the user asks for Word's font on every printout:

- **Never copy it into the app's assets**: the licence forbids it. Load it at run time from `%WINDIR%\Fonts` (or the user's fonts folder) and fall back to the bundled font. Calibri's fsType 8 allows embedding it in the PDF.
- **Check the file, not the name.** Calibri 5.x, the one on font download sites, has **no Arabic**; 6.x (Windows 10/11) has. Keep the font only if its cmap has alef, its final form and lam-alef (`check_glyphs.py --metrics` says).
- **Its Arabic may not rest on its baseline.** Calibri's Arabic letters rest 0.078 em above it (its Latin rests on it), so Arabic on a ruled line floats 0.03 cm at 11 pt. Measure the bottom of «ـ» (`--metrics` prints it as "Arabic rests at") and lower Arabic by that much (`FormFont.seat` in the example).
- **Tashkeel placed by GPOS print misplaced.** The pdf package doesn't apply GPOS mark positioning, and Calibri draws its marks around the glyph origin: «تحريراً في» printed with the tanween low, in the space before «في». Rasterize a string with tanween. If the marks land wrong, strip them for print (U+064B–0652, U+0670, and the presentation forms FC5E–FC63). Splitting the marks into their own spans with another font crashes the bidi step (`RangeError` in `Normalization._compose`).

## 3. The print call carries the paper

- **One function returns the document and its paper format** (`ChequePrint(document, format)`), and every call site passes both:
  ```dart
  await Printing.directPrintPdf(printer: printer, format: job.format, onLayout: (_) => job.document.save());
  await Printing.layoutPdf(format: job.format, onLayout: (_) => job.document.save());
  ```
  `directPrintPdf` defaults `format` to `PdfPageFormat.standard`, so without it the Windows driver gets A4 and every value lands in the wrong place. Every sample PDF is still right and every test still green, so a call that loses `format:` in a refactor only shows on paper. A test asserts the job's format, so the size can't get lost.
- **Feed direction.** A form fed **narrow side first** gets a portrait page of the paper's turned size, with the content turned in the PDF:
  ```dart
  pw.Transform.rotateBox(angle: math.pi / 2, unconstrained: true, child: cheque)
  ```
  Turning it yourself doesn't depend on the driver's landscape setting (90° or 270° depending on the driver). **`unconstrained: true` is required**: without it the child is laid out at the page's width before it turns (a wide form squeezed to the page's narrow width), and most of it falls off the page with no error. Keep the preview unturned, and rasterize the turned sample to see which edge is on top. The edge that goes in first is the top of the page.
- On Windows, a `format` passed to `printing` builds a new DEVMODE from scratch, so the driver's private options are lost. For a plain-paper print where the queue's own settings matter, use `usePrinterSettings: true`. Before relying on a custom paper size, read the queue's PrintCapabilities. Some copier queues have a minimum custom paper size, and a form smaller than that can't be sent as its own paper size.

## 4. Measure the PDF, don't eyeball it

Looking at a PNG can't tell 7.6 cm from 7.9 cm. The PDF test writes, next to each sample, what each value's ink must look like, built from the same layout constants the builder uses (`writePdfWithMeasures` and `MeasuredField` in the PDF harness):

```dart
await writePdfWithMeasures(buildChequePdf(values, font: font, guides: true).document, 'cheque_typical', fields: [
  MeasuredField('payee',
      window: [payeeEnd - 0.2, payeeLine - 0.75, payeeStart + 0.6, payeeLine + 0.22],
      baseline: payeeLine, start: payeeStart, endLimit: payeeEnd, anchorRight: true),
  …
]);
```

```bash
flutter test test/pdf
python3 <flutter-ui-verify>/scripts/measure_pdf.py test/pdf/out           # checks every *.measure.json
python3 <flutter-ui-verify>/scripts/measure_pdf.py cheque.pdf --window payee 1.0 2.5 14.0 3.6   # ad hoc
```

It rasterizes at 600 dpi (0.004 cm a pixel) and, per field, finds:

- **the baseline**: the bottom of the densest band of ink, not the ink box's bottom, which tails and «/» reach below;
- **the start edge**: where the value starts, within how far its first letter may reach past it (the overhang above) and how far short of it;
- **the end limit**: no ink past it.

Grey guides are lighter than the ink threshold, so the preview PDF can be measured as it is.

Samples, at least:

- typical values;
- the **longest** each field allows, which must shrink and stay on its line;
- values that start with «ا»;
- the per-printer lift (section 6) when there is one;
- the turned printer page and the test sheet, rasterized and looked at.

## 5. Check on paper, and prove the scale first

Some defects only show on paper. Print once and photograph it flat. Then:

1. **Prove the scale before measuring positions.** Put a 10 cm ruler with 1 cm ticks on a test sheet and check it with a real ruler. Anything but 10.0 cm is a driver or printer setting (fit to page, a wrong media size, zoom), not the layout. A common cause: the queue's media size is Letter, so an A4 page is scaled to about 92% (10 cm → 9.2 cm) while the PDF is exact. On Windows, read the queue's print ticket and set its media size; don't move the values to compensate.
2. **Measure each field against its nearest printed line or box edge,** not in photo pixels per cm. Perspective changes the scale across a photo, by 10% or more between one edge and the other.
3. **Hand-cut test paper is ±1 mm.** Ask for its size before you read a shift as a layout error. A form cut 1 mm short moves everything 1 mm, because printers register from the leading edge.
4. **Offer a test print.** It prints the form's own lines in black on plain paper cut to the form's size, plus the ruler (`buildChequeTestSheet` in the example). The user holds it over a real form against the light, and a printer's offset shows before a real form is used.

## 6. Every printer the user prints on

The same PDF can land right on one printer and 1–2 mm low on another. No single position fits every printer:

- Pick the printer **before** building the PDF.
- Give the builder a `lift` (cm) that moves **only the values**, never the lines, frame or guides.
- Keep it per printer, set by the user after a test print (▲/▼, saved at once), keyed on the queue name; a printer nobody has set gets 0 (`ChequeLayout.printerLift(name, saved)`). No list of models in code.
- Test that an unset printer gets none, and write a sample with the lift so it is measured like the rest.

## Checklist

- [ ] Positions are constants in cm from the paper's corner; page = paper, zero margins.
- [ ] Values sit with their baseline on the line, read from the font's metrics; shrink-to-fit keeps the baseline; start room inside any `FittedBox`.
- [ ] Every value ≥ 0.2 cm from printed text; values beside a printed label are anchored away from it.
- [ ] One function returns the document and its format; every print call passes `format`; a test asserts it.
- [ ] A form fed narrow side first is turned in the PDF with `rotateBox(unconstrained: true)`; the turned sample is rasterized and looked at.
- [ ] A system font is loaded at run time with a fallback, checked for Arabic, its seat measured, its marks checked on a raster.
- [ ] Samples: typical, longest, leading «ا», lift; `measure_pdf.py` passes on all of them.
- [ ] On paper: the ruler measures 10.0 cm; fields measured against the printed lines; every printer checked; a test print offered.

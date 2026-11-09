# Printed documents (PDF)

Screens get a layout matrix. Printed documents need their own loop, because the `pdf` package fails quietly:

- **A fixed `pw.Page` drops what doesn't fit.** It lays the content out in the page's content area; a `pw.Column` that runs past it stops there, so the blocks after that point are never painted and the block that crossed the edge is cut off. No exception, no overflow stripe, and the test that builds the PDF stays green. Three entries in a payment box were enough to drop a bill's signature row.
- **Overlays at a fraction of the page stay put while the content moves.** A stamp placed with `pw.Alignment(0.6, 0.7)` in a page-level `pw.Stack` landed on the date line («تحريراً في») after the header grew.
- **`maxLines` truncates without an ellipsis**, and an empty optional field can print as a bare label or `null`.

So: **render with sample data → check the marked blocks → rasterize → open every page.**

## 1. Make the document testable

Build each document in plain Dart, without plugin calls, so `flutter test` can run it:

- one function takes the data, the print theme (fonts), the labels and direction, and a `mark` callback, and returns a `pw.Document`;
- the caller loads the fonts once (`pw.Font.ttf(await rootBundle.load(...))`), the same family as the app;
- `Printing.layoutPdf` / `Printing.sharePdf` (printing package) only at the call site.

```dart
typedef PdfMark = pw.Widget Function(String name, pw.Widget child);
pw.Widget noPdfMark(String name, pw.Widget child) => child;

pw.Document buildInvoicePdf(
  PrintableInvoice data, {
  required pw.ThemeData theme,
  InvoicePdfLabels labels = InvoicePdfLabels.en,
  PdfMark mark = noPdfMark, // production passes nothing
}) { … }
```

Mark the blocks a reader must find on paper: signatures, totals, the stamp, the date line, the footer. `mark(InvoicePdfMarks.signatures, signaturesRow)` changes nothing in production; in the test it records where the block was painted. Reference: `../flutter-modern-ui/assets/examples/invoice_pdf.dart`.

## 2. Sample cases and checks

Copy `assets/pdf/` into `test/pdf/` (needs `pdf` in the app's dependencies) and edit only `pdf_cases.dart`:

| File | Does |
|---|---|
| `pdf_harness.dart` | records where marked blocks are painted; checks them |
| `pdf_cases.dart` | the documents, their sample data and what must survive on paper |
| `pdf_test.dart` | renders every case to `test/pdf/out/<case>.pdf` and runs the checks |

For each document, at least:

| Case | Data | Catches |
|---|---|---|
| typical | realistic values | the everyday look |
| minimal | every optional field empty: no phone, no notes, no payments | bare labels, `null`, stray separators, empty boxes |
| longest | the longest values the forms allow: names, most rows, max-length notes, the biggest amount | dropped blocks, cut text, stamp collisions |
| each direction | Arabic RTL and every LTR language the app prints | reversed numbers and phones, columns on the wrong side |

Each `PdfCase` lists the blocks that must be painted (`mustShow`), pairs that must not overlap (`mustNotOverlap`, such as the stamp and the date line) and `maxPages`. Every marked block must also lie inside the page's content area: the page format's margins, or `margin:` when the document sets `pw.Page(margin:)` itself.

```bash
flutter test test/pdf        # writes test/pdf/out/<case>.pdf and runs the checks
```

A failure reads:

```
test/pdf/out/invoice_ar_longest.pdf (1 page)
  • "signatures" was not painted: the content before it ran past the page, and a fixed pw.Page drops the rest without an error. Add a line budget, shorten the content or use pw.MultiPage
  • "stamp" overlaps "issuedAt" on page 1 (60 × 14 pt): anchor overlays inside the block they belong to, not at a fraction of the page
```

The checks prove that blocks fit. They don't prove the page looks right: always look.

## 3. Rasterize and look

`Printing.raster` needs pdfium from the printing plugin, which `flutter test` doesn't load, so rasterize outside the test run with `scripts/rasterize_pdf.py` (in this skill's folder):

```bash
python3 <flutter-ui-verify>/scripts/rasterize_pdf.py test/pdf/out --text   # Windows: py instead of python3
```

It uses PyMuPDF when installed (`pip install pymupdf`; the core is `pymupdf.open(path)[0].get_pixmap(dpi=150).save(png)`), otherwise poppler (`pdftoppm -png -r 150 file.pdf out`). It writes `<case>_p<N>.png` next to each PDF and prints the paths. `--text` prints each page's text and flags `null`, `NaN`, `Infinity`, `undefined` and `Instance of`.

Open every PNG with the Read tool and review each page in this order:

1. **The bottom of the page first**: signatures, stamp, footer and page number present and inside the margins.
2. **Overlays**: the stamp sits in its slot and covers no text.
3. **Longest case**: names and notes complete (nothing cut mid-line), rows inside their box, the budget's summary row ("Earlier payments (9)") readable.
4. **Empty fields**: no bare labels, `null`, dashes standing in for values or empty boxes; the spacing closes up.
5. **RTL**: Arabic joined (no boxes, no isolated letters); numbers, dates, phones and amounts in reading order; amounts aligned at the end edge.
6. **Print legibility**: text ≥ 8 pt, rules ≥ 0.5 pt, near-black ink; meaning survives a black-and-white printer (no status by color alone).
7. **Margins**: content inside the printer's safe area (about 10 mm from the paper edge on office printers, 3–5 mm on receipt rolls).

Write findings as *page · where · issue · fix*. Fix, re-render, rasterize again and compare before with after: a change to a header moves everything below it.

## Fixing what the checks find

| Finding | Fix |
|---|---|
| A block not painted, or below the content area | a line budget for the block that grows; cap the input in the form; or `pw.MultiPage` with a repeating header and footer when the document may run long |
| Stamp overlaps text | anchor it inside the block it belongs to: a `pw.Stack` in the signature slot with `pw.PositionedDirectional`, sized to fit the signing space |
| Name or notes cut off | a bigger budget for that field, smaller type down to 8 pt at most, or a shorter `maxLength` in the form |
| Runs to an extra page | a budget, or allow it (`maxPages`) with a repeating header |
| `null` or a bare label | leave out the whole row when the value is empty |

## Line budgets

A budget is how many rows or lines a block may use, chosen so that the longest case still fits, and enforced where the data is entered:

- rows: `paymentRows = 4`; with more, print the 3 newest and one summary row (count and total);
- text: `notesMaxLength = 160` (3 lines at 9 pt in the box), used as the form field's `maxLength`;
- names: `maxLines: 2`, proven by the longest-name sample.

Keep the budgets as named constants next to the document code, so the form, the document and the longest sample use the same numbers.

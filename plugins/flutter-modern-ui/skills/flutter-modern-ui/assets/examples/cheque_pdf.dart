// Printing values onto a pre-printed form: a cheque. The form's lines and
// labels are already on the paper; the app prints only the values, each on
// a spot measured on the paper with a ruler.
//
// What it shows (flutter-ui-verify/references/preprinted-forms.md):
// - every position a constant in cm from the paper's top-left corner, named
//   after what was measured (ChequeLayout);
// - one function returns the document AND its paper format (ChequePrint), so
//   a print call can't lose the size: a `directPrintPdf` without `format:`
//   sends A4 and every value lands in the wrong place, with every test green;
// - text placed by its baseline on the printed line, from the font's real
//   metrics (FormFont); tails («ي ع ر و ن», «/») go under the line, as in
//   handwriting;
// - long values shrink to fit with the baseline held still, and the box
//   keeps room on the start side, because the pdf package measures some
//   Arabic runs narrower than it draws them and a FittedBox would clip the
//   first «ا»;
// - an amount anchored away from the printed currency label next to it;
// - `lift`: moves the values (never the lines) for a printer model that
//   prints low; `forPrinter`: the page turned for a form fed narrow side
//   first;
// - the preview is the same PDF plus grey guides, so it can't drift from
//   the print; a test sheet on A4 with the form's lines and a 10 cm ruler.
//
// The positions here are an example form's. Measure your own.

import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'invoice_pdf.dart' show PdfMark, noPdfMark;

/// Every position on the form, in cm from the paper's top-left corner, as
/// measured on a real form with a ruler.
abstract final class ChequeLayout {
  /// The paper.
  static const double width = 17.5;
  static const double height = 8.0;

  /// The printed lines the values sit on, from the top edge.
  static const double payeeLine = 3.60;
  static const double wordsLine = 4.50;
  static const double dateLine = 5.80;

  /// Arabic values start (right edge) clear of the printed label
  /// («ادفعوا لأمر», «مبلغ وقدره») and stop before the left margin.
  static const double payeeStart = 14.60;
  static const double payeeEnd = 1.40;
  static const double wordsStart = 14.60;
  static const double wordsEnd = 1.40;

  /// The date reads left to right, after the printed «التاريخ».
  static const double dateStart = 1.40;
  static const double dateEnd = 5.00;

  /// The amount box, with «USD» printed at its left: the amount is anchored
  /// to the box's right, so spare room goes on the label's side.
  static const double amountBoxLeft = 12.40;
  static const double amountBoxRight = 16.80;
  static const double amountBoxTop = 5.20;
  static const double amountBoxBottom = 6.30;
  static const double currencyLabelEnd = 13.20;
  static const double amountStart = 16.50;
  static const double amountLine = 5.95;

  /// Point sizes.
  static const double valueSize = 13;
  static const double wordsSize = 11;

  /// The least space between a value and the form's own printed text.
  /// Printers place a page a millimetre or two off; 0.1 cm is eaten by that.
  static const double clearance = 0.2;

  static const PdfPageFormat pageFormat = PdfPageFormat(width * PdfPageFormat.cm, height * PdfPageFormat.cm, marginAll: 0);

  /// The same form fed into the printer narrow side first: a portrait page
  /// the cheque is turned onto (`buildChequePdf(forPrinter: true)`).
  static const PdfPageFormat printFormat = PdfPageFormat(height * PdfPageFormat.cm, width * PdfPageFormat.cm, marginAll: 0);

  /// The values' lift for a printer that prints low, in cm, as saved for
  /// that printer after its test sheet (`saved`: printer name → cm); 0 for a
  /// printer nobody has set yet. Never a model list in code.
  static double printerLift(String printerName, Map<String, double> saved) => saved[printerName] ?? 0;
}

/// A font for printing, with the metrics needed to put its baseline on a
/// printed line. Read from the file, never guessed:
/// `check_glyphs.py --font <file> --metrics` prints the same values.
class FormFont {
  const FormFont(this.font, {required this.ascent, required this.descent, this.seat = 0});

  /// [seat]: where the font's Arabic letters rest, in em above its baseline
  /// (the bottom of «ـ»). 0 for most fonts; Calibri's Arabic rests 0.078 em
  /// above it, so it is lowered by that much to sit on the line.
  factory FormFont.fromBytes(ByteData data, {double seat = 0}) {
    final ttf = TtfParser(data);
    return FormFont(
      pw.Font.ttf(data),
      ascent: ttf.ascent / ttf.unitsPerEm,
      descent: -ttf.descent / ttf.unitsPerEm,
      seat: seat,
    );
  }

  final pw.Font font;

  /// Above and below the baseline, in em, as the pdf package lays text out
  /// (the hhea table).
  final double ascent;
  final double descent;
  final double seat;
}

/// The app's print font from its assets.
Future<FormFont> loadFormFont({String asset = 'assets/fonts/IBMPlexSansArabic-Regular.ttf'}) async =>
    FormFont.fromBytes(await rootBundle.load(asset));

class ChequeValues {
  const ChequeValues({required this.payee, required this.amountInWords, required this.date, required this.amount});

  final String payee;
  final String amountInWords;
  final String date;
  final String amount;
}

/// A document and the paper it was built for. Print with both:
///
/// ```dart
/// final job = buildChequePdf(values, font: font, forPrinter: true, lift: ChequeLayout.printerLift(printer.name, settings.printerLifts));
/// await Printing.directPrintPdf(printer: printer, format: job.format, onLayout: (_) => job.document.save());
/// ```
class ChequePrint {
  const ChequePrint(this.document, this.format);

  final pw.Document document;
  final PdfPageFormat format;
}

/// Marks for the PDF checks and for measure_pdf.py.
abstract final class ChequeMarks {
  static const String payee = 'payee';
  static const String words = 'words';
  static const String date = 'date';
  static const String amount = 'amount';
}

/// The share of a value's size kept free on its start side, inside the box
/// a FittedBox clips to: the pdf package measures some Arabic runs narrower
/// than it draws them («ادفعوا», «اثنا عشر»), and without this room the
/// first letter is cut off.
const double chequeStartRoom = 0.3;

/// The cheque. [guides]: draw the form's lines and labels in grey, for the
/// on-screen preview (the same PDF as the print). [forPrinter]: turn the
/// page for a form fed narrow side first. [lift]: raise the values (cm) for
/// a printer that prints low. [startRoom]: see [chequeStartRoom].
ChequePrint buildChequePdf(
  ChequeValues values, {
  required FormFont font,
  bool guides = false,
  bool forPrinter = false,
  double lift = 0,
  double startRoom = chequeStartRoom,
  PdfMark mark = noPdfMark,
}) {
  final cheque = pw.SizedBox(
    width: ChequeLayout.width * PdfPageFormat.cm,
    height: ChequeLayout.height * PdfPageFormat.cm,
    child: pw.Stack(
      children: [
        if (guides) ..._guides(font),
        _onLine(
          values.payee,
          name: ChequeMarks.payee,
          line: ChequeLayout.payeeLine - lift,
          start: ChequeLayout.payeeStart,
          end: ChequeLayout.payeeEnd,
          size: ChequeLayout.valueSize,
          font: font,
          rtl: true,
          startRoom: startRoom,
          mark: mark,
        ),
        _onLine(
          values.amountInWords,
          name: ChequeMarks.words,
          line: ChequeLayout.wordsLine - lift,
          start: ChequeLayout.wordsStart,
          end: ChequeLayout.wordsEnd,
          size: ChequeLayout.wordsSize,
          font: font,
          rtl: true,
          startRoom: startRoom,
          mark: mark,
        ),
        _onLine(
          values.date,
          name: ChequeMarks.date,
          line: ChequeLayout.dateLine - lift,
          start: ChequeLayout.dateStart,
          end: ChequeLayout.dateEnd,
          size: ChequeLayout.wordsSize,
          font: font,
          rtl: false,
          startRoom: startRoom,
          mark: mark,
        ),
        // Digits read left to right, but the amount is anchored at the
        // box's right, away from the printed «USD».
        _onLine(
          values.amount,
          name: ChequeMarks.amount,
          line: ChequeLayout.amountLine - lift,
          start: ChequeLayout.amountStart,
          end: ChequeLayout.currencyLabelEnd + ChequeLayout.clearance,
          size: ChequeLayout.valueSize,
          font: font,
          rtl: false,
          anchorRight: true,
          startRoom: startRoom,
          mark: mark,
        ),
      ],
    ),
  );

  final document = pw.Document();
  if (!forPrinter) {
    document.addPage(pw.Page(pageFormat: ChequeLayout.pageFormat, build: (_) => cheque));
    return ChequePrint(document, ChequeLayout.pageFormat);
  }
  // A quarter turn counterclockwise: the amount end is the top of the page
  // and enters the printer first. Turning it here doesn't depend on the
  // driver's landscape setting (90° or 270° depending on the driver).
  // `unconstrained`: without it the cheque is laid out at the page's narrow
  // width before it turns, and most of it falls off the page.
  document.addPage(
    pw.Page(
      pageFormat: ChequeLayout.printFormat,
      build: (_) => pw.Transform.rotateBox(angle: math.pi / 2, unconstrained: true, child: cheque),
    ),
  );
  return ChequePrint(document, ChequeLayout.printFormat);
}

/// One value sitting on a printed line: its baseline on [line], its start
/// at [start] (the right edge for Arabic, or with [anchorRight]), never past
/// [end]. A value too long for the room shrinks, around its baseline.
pw.Widget _onLine(
  String text, {
  required String name,
  required double line,
  required double start,
  required double end,
  required double size,
  required FormFont font,
  required bool rtl,
  bool anchorRight = false,
  required double startRoom,
  required PdfMark mark,
}) {
  const cm = PdfPageFormat.cm;
  final right = rtl || anchorRight;
  final a = font.ascent;
  final d = font.descent;
  final room = startRoom * size;
  final width = (right ? start - end : end - start) * cm + room;
  final height = (a + d) * size;
  // The baseline is one ascent below the box's top. Arabic that rests above
  // the font's baseline is lowered by its seat.
  final top = line * cm - a * size + (rtl ? font.seat * size : 0);
  final left = right ? end * cm : start * cm - room;
  // The point that stays still when the FittedBox shrinks the text: the
  // baseline, d / (a + d) up from the bottom (the pdf package's y points up,
  // so bottom is -1).
  final baseline = 2 * d / (a + d) - 1;

  return pw.Positioned(
    left: left, // lint-ui: ok (a spot on paper, measured from the left edge)
    top: top,
    child: mark(
      name,
      pw.SizedBox(
        width: width,
        height: height,
        child: pw.FittedBox(
          fit: pw.BoxFit.scaleDown,
          alignment: pw.Alignment(right ? 1 : -1, baseline),
          child: pw.Padding(
            padding: right ? pw.EdgeInsets.only(right: room) : pw.EdgeInsets.only(left: room), // lint-ui: ok (paper)
            child: pw.Text(
              text,
              style: pw.TextStyle(font: font.font, fontSize: size, color: PdfColors.black),
              textDirection: rtl ? pw.TextDirection.rtl : pw.TextDirection.ltr,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Light enough that measure_pdf.py doesn't count it as ink.
const PdfColor _guide = PdfColors.grey500;

/// The form's own small print (labels) and the test sheet's notes.
const double _labelSize = 9;
const double _noteSize = 11;

/// The test sheet's ruler, in cm.
const int _rulerCm = 10;

/// The form's own printing, in grey: lines, the amount box and its labels.
/// For the preview only; the paper already has them.
List<pw.Widget> _guides(FormFont font, {PdfColor color = _guide}) {
  const cm = PdfPageFormat.cm;

  pw.Widget rule(double y, double from, double to) => pw.Positioned(
        left: from * cm, // lint-ui: ok (paper)
        top: y * cm,
        child: pw.Container(width: (to - from) * cm, height: 0.6, color: color),
      );

  // Captions are fixed strings that fit: a plain Align, no FittedBox (it
  // would clip a leading «ا»), and ending short of their line by the spill.
  pw.Widget caption(String text, double y, double from, double to) => pw.Positioned(
        left: from * cm, // lint-ui: ok (paper)
        top: (y - 0.45) * cm,
        child: pw.SizedBox(
          width: (to - from - 0.12) * cm,
          height: 0.4 * cm,
          child: pw.Align(
            alignment: pw.Alignment.bottomRight, // lint-ui: ok (Arabic labels end at the line's right)
            child: pw.Text(
              text,
              style: pw.TextStyle(font: font.font, fontSize: _labelSize, color: color),
              textDirection: pw.TextDirection.rtl,
            ),
          ),
        ),
      );

  return [
    pw.Positioned.fill(child: pw.Container(decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.6)))),
    rule(ChequeLayout.payeeLine, ChequeLayout.payeeEnd, ChequeLayout.payeeStart + 2.2),
    caption('ادفعوا لأمر', ChequeLayout.payeeLine, ChequeLayout.payeeStart + 0.2, ChequeLayout.payeeStart + 2.2),
    rule(ChequeLayout.wordsLine, ChequeLayout.wordsEnd, ChequeLayout.wordsStart + 2.2),
    caption('مبلغ وقدره', ChequeLayout.wordsLine, ChequeLayout.wordsStart + 0.2, ChequeLayout.wordsStart + 2.2),
    rule(ChequeLayout.dateLine, ChequeLayout.dateStart, ChequeLayout.dateEnd + 1.6),
    caption('التاريخ', ChequeLayout.dateLine, ChequeLayout.dateEnd + 0.2, ChequeLayout.dateEnd + 1.6),
    pw.Positioned(
      left: ChequeLayout.amountBoxLeft * cm, // lint-ui: ok (paper)
      top: ChequeLayout.amountBoxTop * cm,
      child: pw.Container(
        width: (ChequeLayout.amountBoxRight - ChequeLayout.amountBoxLeft) * cm,
        height: (ChequeLayout.amountBoxBottom - ChequeLayout.amountBoxTop) * cm,
        decoration: pw.BoxDecoration(border: pw.Border.all(color: color, width: 0.6)),
        padding: const pw.EdgeInsets.symmetric(horizontal: 3), // lint-ui: ok (paper)
        alignment: pw.Alignment.centerLeft, // lint-ui: ok (USD is printed at the box's left)
        child: pw.Text('USD', style: pw.TextStyle(font: font.font, fontSize: _labelSize, color: color)),
      ),
    ),
  ];
}

/// A test print on plain A4: the form's lines and box in black where the
/// form will sit, and a 10 cm ruler. Hold it over a real form against the
/// light to see a printer's offset before a form is used; measure the ruler
/// first: anything but 10 cm is the driver scaling the page (fit to page, a
/// wrong media size), not the layout.
ChequePrint buildChequeTestSheet({required FormFont font}) {
  const cm = PdfPageFormat.cm;
  const a4 = PdfPageFormat(21 * cm, 29.7 * cm, marginAll: 0);
  const left = (21.0 - ChequeLayout.width) / 2;
  const top = 3.0;

  final ruler = pw.SizedBox(
    width: _rulerCm * cm,
    height: 1.2 * cm, // lint-ui: ok (paper)
    child: pw.Stack(
      children: [
        pw.Positioned(left: 0, top: 0, child: pw.Container(width: _rulerCm * cm, height: 0.8, color: PdfColors.black)), // lint-ui: ok (paper)
        for (var i = 0; i <= _rulerCm; i++)
          pw.Positioned(
            left: i * cm - 0.4, // lint-ui: ok (paper)
            top: 0,
            child: pw.Container(width: 0.8, height: (i % 5 == 0 ? 0.5 : 0.3) * cm, color: PdfColors.black),
          ),
        pw.Positioned(
          left: 0, // lint-ui: ok (paper)
          top: 0.6 * cm,
          child: pw.Text('$_rulerCm cm', style: pw.TextStyle(font: font.font, fontSize: _labelSize)),
        ),
      ],
    ),
  );

  final document = pw.Document()
    ..addPage(
      pw.Page(
        pageFormat: a4,
        build: (_) => pw.Stack(
          children: [
            pw.Positioned(
              left: left * cm, // lint-ui: ok (paper)
              top: (top - 1.6) * cm,
              child: pw.Text(
                'طباعة تجريبية: ضع الورقة فوق نموذج حقيقي مقابل الضوء',
                style: pw.TextStyle(font: font.font, fontSize: _noteSize),
                textDirection: pw.TextDirection.rtl,
              ),
            ),
            pw.Positioned(
              left: left * cm, // lint-ui: ok (paper)
              top: top * cm,
              child: pw.SizedBox(
                width: ChequeLayout.width * cm,
                height: ChequeLayout.height * cm,
                child: pw.Stack(children: _guides(font, color: PdfColors.black)),
              ),
            ),
            pw.Positioned(left: left * cm, top: (top + ChequeLayout.height + 1.5) * cm, child: ruler), // lint-ui: ok (paper)
          ],
        ),
      ),
    );
  return ChequePrint(document, a4);
}

// CI only (copied to test/ci/ by scripts/sandbox.sh): the pre-printed form
// example (examples/cheque_pdf.dart) renders its samples and writes, next to
// each, the *.measure.json that measure_pdf.py checks after rasterizing:
// every value's baseline on its printed line, its start where it was
// measured, nothing past its end, a shrunk value still on its line, a
// printer lift moving the values only. It also proves that the print job
// carries its paper size and that the turned page is the turned format.

import 'package:app/examples/cheque_pdf.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';

import '../pdf/pdf_harness.dart';

const ChequeValues _typical = ChequeValues(
  payee: 'مكتبة الحكمة',
  amountInWords: 'اثنا عشر ألفاً وخمسمئة دولار فقط لا غير',
  date: '12/11/2026',
  amount: '12,500.00',
);

/// Longer than the line: shrinks, and must stay on its line. Starts with a
/// bare «ا», the letter a FittedBox with no start room cuts off.
const ChequeValues _longest = ChequeValues(
  payee: 'ادفعوا لأمر اتحاد الجمعيات التعاونية الزراعية لتسويق الخضار والفواكه والحمضيات',
  amountInWords: 'اثنا عشر مليوناً وتسعمئة وتسعة وتسعون ألفاً وتسعمئة وتسعة وتسعون دولاراً وتسعة وتسعون سنتاً فقط لا غير',
  date: '31/12/2026',
  amount: '12,999,999.99',
);

/// The fields of the cheque as measure_pdf.py checks them, from the same
/// constants the builder uses.
List<MeasuredField> _fields({required double size, double lift = 0, bool reportOnly = false}) {
  final room = chequeStartRoom * size * 2.54 / 72;
  return [
    MeasuredField(
      ChequeMarks.payee,
      window: [ChequeLayout.payeeEnd - 0.2, ChequeLayout.payeeLine - lift - 0.75, ChequeLayout.payeeStart + 0.6, ChequeLayout.payeeLine - lift + 0.22],
      baseline: ChequeLayout.payeeLine - lift,
      start: ChequeLayout.payeeStart,
      endLimit: ChequeLayout.payeeEnd,
      anchorRight: true,
      startPast: room,
      reportOnly: reportOnly,
    ),
    MeasuredField(
      ChequeMarks.words,
      window: [ChequeLayout.wordsEnd - 0.2, ChequeLayout.wordsLine - lift - 0.55, ChequeLayout.wordsStart + 0.6, ChequeLayout.wordsLine - lift + 0.22],
      baseline: ChequeLayout.wordsLine - lift,
      start: ChequeLayout.wordsStart,
      endLimit: ChequeLayout.wordsEnd,
      anchorRight: true,
      startPast: room,
      reportOnly: reportOnly,
    ),
    MeasuredField(
      ChequeMarks.date,
      window: [ChequeLayout.dateStart - 0.6, ChequeLayout.dateLine - lift - 0.55, ChequeLayout.dateEnd + 0.2, ChequeLayout.dateLine - lift + 0.22],
      baseline: ChequeLayout.dateLine - lift,
      start: ChequeLayout.dateStart,
      endLimit: ChequeLayout.dateEnd,
      reportOnly: reportOnly,
    ),
    MeasuredField(
      ChequeMarks.amount,
      window: [ChequeLayout.currencyLabelEnd + 0.05, ChequeLayout.amountLine - lift - 0.65, ChequeLayout.amountBoxRight + 0.3, ChequeLayout.amountLine - lift + 0.22],
      baseline: ChequeLayout.amountLine - lift,
      start: ChequeLayout.amountStart,
      endLimit: ChequeLayout.currencyLabelEnd + ChequeLayout.clearance,
      anchorRight: true,
      reportOnly: reportOnly,
    ),
  ];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late FormFont font;

  setUpAll(() async {
    font = FormFont.fromBytes(await rootBundle.load('assets/fonts/IBMPlexSansArabic-Regular.ttf'));
  });

  test('the font metrics come from the file (hhea), as check_glyphs.py --metrics prints them', () {
    expect(font.ascent, closeTo(1.085, 0.001));
    expect(font.descent, closeTo(0.415, 0.001));
  });

  test('the print job carries its paper: preview, turned for the printer, the test sheet', () {
    const values = _typical;
    expect(buildChequePdf(values, font: font).format, ChequeLayout.pageFormat);
    final turned = buildChequePdf(values, font: font, forPrinter: true).format;
    expect(turned, ChequeLayout.printFormat);
    expect(turned.width, closeTo(ChequeLayout.height * PdfPageFormat.cm, 0.01));
    expect(turned.height, closeTo(ChequeLayout.width * PdfPageFormat.cm, 0.01));
    expect(buildChequeTestSheet(font: font).format.width, closeTo(21 * PdfPageFormat.cm, 0.01));
  });

  test('printer lift: the saved value for that printer, 0 for one not set', () {
    const saved = {'Front desk printer': 0.1, 'Back office printer': 0.0};
    expect(ChequeLayout.printerLift('Front desk printer', saved), 0.1);
    expect(ChequeLayout.printerLift('Back office printer', saved), 0);
    expect(ChequeLayout.printerLift('New printer', saved), 0);
  });

  test('cheque samples and their measures', () async {
    // The preview: the same PDF plus grey guides (measure_pdf.py ignores grey).
    await writePdfWithMeasures(
      buildChequePdf(_typical, font: font, guides: true).document,
      'cheque_typical',
      fields: _fields(size: ChequeLayout.valueSize),
    );
    await writePdfWithMeasures(
      buildChequePdf(_longest, font: font, guides: true).document,
      'cheque_longest',
      fields: _fields(size: ChequeLayout.valueSize),
    );
    // A printer that prints low: only the values move.
    await writePdfWithMeasures(
      buildChequePdf(_typical, font: font, guides: true, lift: 0.1).document,
      'cheque_typical_lift',
      fields: _fields(size: ChequeLayout.valueSize, lift: 0.1),
    );
    // No start room: measured and reported, to show what the room is for.
    await writePdfWithMeasures(
      buildChequePdf(_longest, font: font, startRoom: 0).document,
      'cheque_longest_no_room',
      fields: _fields(size: ChequeLayout.valueSize, reportOnly: true),
    );
    // Turned for the printer, and the test sheet: rasterize and look.
    await writePdfWithMeasures(buildChequePdf(_typical, font: font, forPrinter: true).document, 'cheque_typical_print');
    await writePdfWithMeasures(buildChequeTestSheet(font: font).document, 'cheque_test_sheet');
  });
}

// CI only (copied to test/ci/ by scripts/sandbox.sh): proves the printed-
// document checks catch what a fixed pw.Page hides, and that the recorded
// rectangles are real page coordinates.

import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../pdf/pdf_harness.dart';

/// 300 × 400 pt with 20 pt margins: the content area is 260 × 360 at (20, 20).
const PdfPageFormat _format = PdfPageFormat(300, 400, marginAll: 20);

pw.Document _page(
  pw.Widget Function(String name, pw.Widget child) mark, {
  int lines = 3,
  bool stampAtPageCorner = false,
}) {
  final document = pw.Document();
  document.addPage(
    pw.Page(
      pageFormat: _format,
      build: (context) => pw.Stack(
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              mark('date', pw.SizedBox(height: 20, child: pw.Text('Issued 08/11/2026'))),
              for (var i = 0; i < lines; i++) pw.SizedBox(height: 20, child: pw.Text('Line $i')),
              pw.Spacer(),
              mark('signatures', pw.SizedBox(height: 40, child: pw.Text('Signatures'))),
            ],
          ),
          // Placed relative to the page, not to the block it belongs to.
          if (stampAtPageCorner) pw.Positioned(left: 0, top: 0, child: mark('stamp', pw.SizedBox(width: 50, height: 50))),
        ],
      ),
    ),
  );
  return document;
}

Future<PdfReport> _render(String name, Future<pw.Document> Function(pw.Widget Function(String, pw.Widget) mark) build) {
  return renderPdfCase(
    PdfCase(
      name,
      build,
      mustShow: const ['date', 'signatures'],
      mustNotOverlap: const [('stamp', 'date')],
      maxPages: 1,
    ),
    outDir: 'test/ci/out',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a page that fits passes, with blocks at their page coordinates', () async {
    final report = await _render('fits', (mark) async => _page(mark));
    expect(report.problems, isEmpty, reason: '$report');

    final date = report.hits['date']!.single;
    expect(date.page, 1);
    expect(date.rect.left, closeTo(20, 0.01));
    expect(date.rect.top, closeTo(380, 0.01));
    expect(date.rect.width, closeTo(260, 0.01));
    expect(date.rect.height, closeTo(20, 0.01));

    // The Spacer pushes the signatures down to the bottom margin.
    final signatures = report.hits['signatures']!.single.rect;
    expect(signatures.bottom, closeTo(20, 0.01));
    expect(signatures.top, closeTo(60, 0.01));
  });

  test('content that runs past a fixed page fails instead of dropping the signatures', () async {
    final report = await _render('overflows', (mark) async => _page(mark, lines: 30));
    expect(report.hits['signatures'] ?? const <PdfHit>[], isEmpty);
    expect(report.problems, contains(startsWith('"signatures" was not painted')));
  });

  test('a stamp placed on the page instead of its block is caught overlapping text', () async {
    final report = await _render('stamp', (mark) async => _page(mark, stampAtPageCorner: true));
    expect(report.problems, contains(startsWith('"stamp" overlaps "date"')));
  });

  test('blocks outside the margins and extra pages are reported', () async {
    final report = await renderPdfCase(
      PdfCase(
        'multi',
        (mark) async {
          final document = pw.Document();
          document.addPage(
            pw.MultiPage(
              pageFormat: _format,
              build: (context) => [
                for (var i = 0; i < 40; i++) pw.SizedBox(height: 20, child: pw.Text('Row $i')),
                mark('signatures', pw.SizedBox(height: 40, child: pw.Text('Signatures'))),
              ],
            ),
          );
          return document;
        },
        maxPages: 1,
        // Pretend the document used wider margins than the format's.
        margin: const pw.EdgeInsets.all(40),
      ),
      outDir: 'test/ci/out',
    );
    expect(report.pages, greaterThan(1));
    expect(report.hits['signatures']!.single.page, report.pages);
    expect(report.problems, contains(startsWith('runs to ${report.pages} pages')));
    expect(report.problems, contains(contains('"signatures" on page ${report.pages} sticks out')));
  });
}

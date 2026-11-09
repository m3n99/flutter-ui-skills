// Renders every printed document in pdf_cases.dart with its sample data,
// writes test/pdf/out/<case>.pdf and checks the marked blocks: painted,
// inside the page's content area, not overlapping, within the page count.
//
//   flutter test test/pdf
//   python3 <flutter-ui-verify>/scripts/rasterize_pdf.py test/pdf/out --text
//
// Then open every PNG: a green run proves the blocks fit, not that the page
// looks right.

import 'package:flutter_test/flutter_test.dart';

import 'pdf_cases.dart';
import 'pdf_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  for (final pdfCase in pdfCases) {
    test('printed ${pdfCase.name}', () async {
      final report = await renderPdfCase(pdfCase);
      expect(report.problems, isEmpty, reason: '\n$report');
    });
  }
}

// Checks for printed documents built with the `pdf` package.
//
// A fixed `pw.Page` never reports overflow: a `pw.Column` that runs past the
// page stops there, so the blocks after that point are never painted, and
// the block that crossed the edge is cut off by the margin or the paper. The
// test that builds the PDF stays green. So the document code marks the blocks
// a reader must find on paper
// (signatures, totals, the stamp, the date line), these helpers record where
// each one was painted, and a case fails when a block leaves the page's
// content area, covers a block it must not cover, or the document runs past
// its page count.
//
// The seam in the document code; production passes nothing:
//
//   typedef PdfMark = pw.Widget Function(String name, pw.Widget child);
//   pw.Widget noPdfMark(String name, pw.Widget child) => child;
//
// Copy into test/pdf/ with pdf_cases.dart and pdf_test.dart; edit only
// pdf_cases.dart. Then rasterize test/pdf/out and look at every page
// (flutter-ui-verify › references/printed-documents.md).

import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Where a marked block was painted.
class PdfHit {
  const PdfHit({required this.page, required this.rect, required this.format});

  /// 1-based page number.
  final int page;

  /// In PDF points, origin at the bottom-left corner of the page.
  final PdfRect rect;

  /// The page's format, margins included.
  final PdfPageFormat format;

  @override
  String toString() => 'page $page: ${rect.left.toStringAsFixed(1)}, ${rect.bottom.toStringAsFixed(1)} '
      '${rect.width.toStringAsFixed(1)} × ${rect.height.toStringAsFixed(1)} pt';
}

/// Records where marked blocks are painted. Pass [mark] to the document code.
class PdfProbes {
  /// Every place each named block was painted (once per page it appears on).
  final Map<String, List<PdfHit>> hits = {};

  pw.Widget mark(String name, pw.Widget child) => _Probe(child, hits.putIfAbsent(name, () => <PdfHit>[]));
}

class _Probe extends pw.SingleChildWidget {
  _Probe(pw.Widget child, this._hits) : super(child: child);

  final List<PdfHit> _hits;

  @override
  void paint(pw.Context context) {
    super.paint(context);
    // The canvas transform maps the space this widget's box is in (its
    // parent's) to the page, so the corners give the absolute rectangle.
    final m = context.canvas.getTransform().storage;
    final b = box!;
    final xs = <double>[];
    final ys = <double>[];
    for (final (x, y) in [(b.left, b.bottom), (b.right, b.bottom), (b.left, b.top), (b.right, b.top)]) {
      xs.add(m[0] * x + m[4] * y + m[12]);
      ys.add(m[1] * x + m[5] * y + m[13]);
    }
    final left = xs.reduce(math.min);
    final bottom = ys.reduce(math.min);
    _hits.add(
      PdfHit(
        page: context.pageNumber,
        rect: PdfRect(left, bottom, xs.reduce(math.max) - left, ys.reduce(math.max) - bottom),
        format: context.page.pageFormat,
      ),
    );
    paintChild(context);
  }
}

/// One printed document rendered with sample data.
class PdfCase {
  const PdfCase(
    this.name,
    this.build, {
    this.mustShow = const [],
    this.mustNotOverlap = const [],
    this.maxPages,
    this.margin,
  });

  /// Output file: `<outDir>/<name>.pdf`.
  final String name;

  /// Builds the document; hand `mark` to the document code.
  final Future<pw.Document> Function(pw.Widget Function(String name, pw.Widget child) mark) build;

  /// Marked blocks that must be painted, such as the signatures.
  final List<String> mustShow;

  /// Pairs of marked blocks that must not overlap (the stamp and the date line).
  final List<(String, String)> mustNotOverlap;

  /// Fails when the document runs to more pages.
  final int? maxPages;

  /// The content area's margins, when the document sets `pw.Page(margin:)`
  /// itself. Default: the margins of the page format.
  final pw.EdgeInsets? margin;
}

/// What a rendered case produced.
class PdfReport {
  const PdfReport({required this.file, required this.pages, required this.hits, required this.problems});

  final File file;
  final int pages;
  final Map<String, List<PdfHit>> hits;
  final List<String> problems;

  @override
  String toString() => [
        '${file.path} ($pages page${pages == 1 ? '' : 's'})',
        for (final problem in problems) '  • $problem',
      ].join('\n');
}

/// Points of slack before a block counts as outside or overlapping.
const double pdfTolerance = 0.5;

/// Builds [pdfCase], writes `<outDir>/<name>.pdf` and checks the marked blocks.
Future<PdfReport> renderPdfCase(PdfCase pdfCase, {String outDir = 'test/pdf/out'}) async {
  final probes = PdfProbes();
  final document = await pdfCase.build(probes.mark);
  final bytes = await document.save();
  final file = File('$outDir/${pdfCase.name}.pdf');
  file.parent.createSync(recursive: true);
  file.writeAsBytesSync(bytes);
  final pages = document.document.pdfPageList.pages.length;
  return PdfReport(
    file: file,
    pages: pages,
    hits: probes.hits,
    problems: checkPdfHits(pdfCase, probes.hits, pages),
  );
}

/// The problems in one rendered document; empty when it passes.
List<String> checkPdfHits(PdfCase pdfCase, Map<String, List<PdfHit>> hits, int pages) {
  final problems = <String>[];

  final maxPages = pdfCase.maxPages;
  if (maxPages != null && pages > maxPages) {
    problems.add('runs to $pages pages (at most $maxPages): add a line budget, or allow more pages with a repeating header');
  }

  for (final name in pdfCase.mustShow) {
    if (hits[name]?.isNotEmpty ?? false) continue;
    // pw.Column stops laying out children once they pass the page height, so
    // on a fixed pw.Page everything after that point is simply never painted.
    problems.add(
      '"$name" was not painted: the content before it ran past the page, and a fixed pw.Page '
      'drops the rest without an error. Add a line budget, shorten the content or use pw.MultiPage',
    );
  }

  for (final MapEntry(key: name, value: list) in hits.entries) {
    for (final hit in list) {
      final outside = _outside(hit, pdfCase.margin);
      if (outside == null) continue;
      problems.add(
        '"$name" on page ${hit.page} $outside: the margin or the paper cuts it off, without an error. '
        'Add a line budget, shorten the content, use pw.MultiPage, or move the block inside the margins',
      );
    }
  }

  for (final (a, b) in pdfCase.mustNotOverlap) {
    for (final hitA in hits[a] ?? const <PdfHit>[]) {
      for (final hitB in hits[b] ?? const <PdfHit>[]) {
        if (hitA.page != hitB.page) continue;
        final width = math.min(hitA.rect.right, hitB.rect.right) - math.max(hitA.rect.left, hitB.rect.left);
        final height = math.min(hitA.rect.top, hitB.rect.top) - math.max(hitA.rect.bottom, hitB.rect.bottom);
        if (width > pdfTolerance && height > pdfTolerance) {
          problems.add(
            '"$a" overlaps "$b" on page ${hitA.page} (${width.toStringAsFixed(0)} × ${height.toStringAsFixed(0)} pt): '
            'anchor overlays inside the block they belong to, not at a fraction of the page',
          );
        }
      }
    }
  }
  return problems;
}

/// Null when [hit] lies inside the page's content area; otherwise how far out.
String? _outside(PdfHit hit, pw.EdgeInsets? margin) {
  final format = hit.format;
  final left = margin?.left ?? format.marginLeft;
  final right = format.width - (margin?.right ?? format.marginRight);
  final bottom = margin?.bottom ?? format.marginBottom;
  final top = format.height - (margin?.top ?? format.marginTop);
  final r = hit.rect;

  String pt(double value) => '${value.toStringAsFixed(1)} pt';
  final parts = <String>[
    if (r.bottom < bottom - pdfTolerance) 'bottom ${pt(bottom - r.bottom)}',
    if (r.top > top + pdfTolerance) 'top ${pt(r.top - top)}',
    if (r.left < left - pdfTolerance) 'left ${pt(left - r.left)}',
    if (r.right > right + pdfTolerance) 'right ${pt(r.right - right)}',
  ];
  if (parts.isEmpty) return null;

  final offPaper = r.bottom < 0 || r.top > format.height || r.left < 0 || r.right > format.width;
  return 'sticks out of the content area (${parts.join(', ')})${offPaper ? ' and off the paper' : ''}';
}

/// A font from the app's assets, for the print theme in tests.
Future<pw.Font> pdfFontAsset(String path) async => pw.Font.ttf(await rootBundle.load(path));

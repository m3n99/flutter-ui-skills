// Reference composition: a printed document built with the `pdf` package
// (add `pdf` to pubspec; the `printing` package shows the print dialog:
// `Printing.layoutPdf(onLayout: (_) => buildInvoicePdf(...).save())`). Shows:
// - the app's font in the PDF (IBM Plex Sans Arabic has Latin and Arabic
//   glyphs), RTL pages through `textDirection`, start/end layout only, and
//   every LTR run (number, date, phone, amount) in its own `pw.Text` inside
//   an LTR `pw.Directionality`: Unicode isolates don't work in `pdf`;
// - line budgets: a fixed `pw.Page` clips overflow without an error, so
//   every block that grows has a cap (payments: the newest rows plus one
//   summary row; notes: a length the form enforces);
// - empty optional fields leave out the whole row or block: no bare label,
//   no "null", no empty payments box;
// - the stamp anchored inside its signature slot, so it moves with the slot
//   instead of landing on text when the content above changes height;
// - a `mark` seam so the sample-PDF test can check where blocks land
//   (flutter-ui-verify › printed documents). Production passes nothing.

import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'sample_data.dart' show formatMoney;

/// Wraps a block so a test can find where it lands on the page.
typedef PdfMark = pw.Widget Function(String name, pw.Widget child);

/// The production [PdfMark]: changes nothing.
pw.Widget noPdfMark(String name, pw.Widget child) => child;

/// Names of the blocks the sample-PDF test checks.
abstract final class InvoicePdfMarks {
  static const String issuedAt = 'issuedAt';
  static const String payments = 'payments';
  static const String totals = 'totals';
  static const String notes = 'notes';
  static const String signatures = 'signatures';
  static const String stamp = 'stamp';
}

/// What one page holds. The longest sample case proves these numbers; the
/// form enforces the text caps (`maxLength`), so nothing reaches the page
/// that the page can't hold.
abstract final class InvoicePdfBudget {
  /// More payments than this: the newest `paymentRows - 1` rows and one
  /// summary row for the earlier ones.
  static const int paymentRows = 4;
  static const int issuerLines = 2;
  static const int customerLines = 2;
  static const int notesLines = 3;

  /// Three lines of body text in the notes box.
  static const int notesMaxLength = 160;
}

/// A5 with 12.7 mm margins: inside the printable area of office printers.
const PdfPageFormat invoicePageFormat = PdfPageFormat(
  14.8 * PdfPageFormat.cm,
  21.0 * PdfPageFormat.cm,
  marginAll: 36,
);

/// Print tokens in PDF points (1 pt = 1/72 in): a 4 pt grid, text ≥ 8 pt,
/// rules ≥ 0.5 pt, near-black ink that survives black-and-white printers.
abstract final class _Print {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;

  static const double caption = 8;
  static const double body = 9;
  static const double strong = 11;
  static const double total = 14;
  static const double title = 16;
  static const double stampText = 7;

  static const double rule = 0.75;
  static const double radius = 8;
  static const double signingSpace = 64;
  static const double stamp = 60;

  static const PdfColor ink = PdfColor.fromInt(0xFF1F2328);
  static const PdfColor muted = PdfColor.fromInt(0xFF59636E);
  static const PdfColor line = PdfColor.fromInt(0xFFD0D7DE);
  static const PdfColor stampInk = PdfColor.fromInt(0xFF1D4ED8);
}

const pw.TextStyle _caption = pw.TextStyle(fontSize: _Print.caption, color: _Print.muted);
const pw.TextStyle _body = pw.TextStyle(fontSize: _Print.body, color: _Print.ink);
const pw.TextStyle _strong = pw.TextStyle(fontSize: _Print.strong, color: _Print.ink, fontWeight: pw.FontWeight.bold);
const pw.TextStyle _total = pw.TextStyle(fontSize: _Print.total, color: _Print.ink, fontWeight: pw.FontWeight.bold);
const pw.TextStyle _title = pw.TextStyle(fontSize: _Print.title, color: _Print.ink, fontWeight: pw.FontWeight.bold);

/// Printed labels and the page direction. Real apps take these from l10n.
class InvoicePdfLabels {
  const InvoicePdfLabels({
    required this.direction,
    required this.title,
    required this.issued,
    required this.due,
    required this.billTo,
    required this.payments,
    required this.earlierPayments,
    required this.total,
    required this.paid,
    required this.balance,
    required this.notes,
    required this.issuerSignature,
    required this.customerSignature,
  });

  final pw.TextDirection direction;
  final String title;
  final String issued;
  final String due;
  final String billTo;
  final String payments;
  final String earlierPayments;
  final String total;
  final String paid;
  final String balance;
  final String notes;
  final String issuerSignature;
  final String customerSignature;

  static const InvoicePdfLabels en = InvoicePdfLabels(
    direction: pw.TextDirection.ltr,
    title: 'Invoice',
    issued: 'Issued',
    due: 'Due',
    billTo: 'Bill to',
    payments: 'Payments',
    earlierPayments: 'Earlier payments',
    total: 'Total',
    paid: 'Paid',
    balance: 'Balance due',
    notes: 'Notes',
    issuerSignature: 'Issued by',
    customerSignature: 'Customer signature',
  );

  static const InvoicePdfLabels ar = InvoicePdfLabels(
    direction: pw.TextDirection.rtl,
    title: 'فاتورة',
    issued: 'تحريراً في',
    due: 'تاريخ الاستحقاق',
    billTo: 'العميل',
    payments: 'الدفعات',
    earlierPayments: 'دفعات سابقة',
    total: 'الإجمالي',
    paid: 'المدفوع',
    balance: 'الرصيد المستحق',
    notes: 'ملاحظات',
    issuerSignature: 'توقيع المحرر',
    customerSignature: 'توقيع العميل',
  );
}

class PrintedPayment {
  const PrintedPayment({required this.date, required this.amountCents, required this.method});

  final DateTime date;
  final int amountCents;
  final String method;
}

class PrintableInvoice {
  const PrintableInvoice({
    required this.issuer,
    required this.number,
    required this.customer,
    this.customerPhone,
    required this.issued,
    required this.due,
    required this.totalCents,
    this.payments = const [],
    this.notes,
    this.sealName,
  });

  final String issuer;
  final String number;
  final String customer;

  /// Optional: the line is left out when empty.
  final String? customerPhone;
  final DateTime issued;
  final DateTime due;
  final int totalCents;

  /// Oldest first.
  final List<PrintedPayment> payments;

  /// Optional, at most [InvoicePdfBudget.notesMaxLength] characters.
  final String? notes;

  /// The short name on the stamp: a seal carries a fixed short name, not
  /// the full legal name. Defaults to [issuer].
  final String? sealName;

  int get paidCents => payments.fold(0, (sum, payment) => sum + payment.amountCents);
}

/// The print theme: the app's font family, loaded once and passed to
/// [buildInvoicePdf]. Point the paths at the project's font assets.
Future<pw.ThemeData> loadPrintTheme({
  String regular = 'assets/fonts/IBMPlexSansArabic-Regular.ttf',
  String bold = 'assets/fonts/IBMPlexSansArabic-Bold.ttf',
}) async {
  return pw.ThemeData.withFont(
    base: pw.Font.ttf(await rootBundle.load(regular)),
    bold: pw.Font.ttf(await rootBundle.load(bold)),
  );
}

/// Builds the invoice as one A5 page. Plain Dart (no plugin calls), so
/// `flutter test` can render it with sample data.
pw.Document buildInvoicePdf(
  PrintableInvoice invoice, {
  required pw.ThemeData theme,
  InvoicePdfLabels labels = InvoicePdfLabels.en,
  PdfMark mark = noPdfMark,
}) {
  final document = pw.Document(theme: theme, title: '${labels.title} ${invoice.number}', author: invoice.issuer);
  document.addPage(
    pw.Page(
      pageFormat: invoicePageFormat,
      textDirection: labels.direction,
      build: (context) => _page(invoice, labels, mark),
    ),
  );
  return document;
}

pw.Widget _page(PrintableInvoice invoice, InvoicePdfLabels labels, PdfMark mark) {
  final notes = invoice.notes?.trim() ?? '';

  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      _header(invoice, labels),
      pw.SizedBox(height: _Print.md),
      pw.Divider(height: _Print.rule, thickness: _Print.rule, color: _Print.line),
      pw.SizedBox(height: _Print.md),
      _parties(invoice, labels, mark),
      pw.SizedBox(height: _Print.lg),
      // No payments: no payments box, not an empty one.
      if (invoice.payments.isNotEmpty) ...[
        mark(InvoicePdfMarks.payments, _payments(invoice, labels)),
        pw.SizedBox(height: _Print.md),
      ],
      mark(InvoicePdfMarks.totals, _totals(invoice, labels)),
      if (notes.isNotEmpty) ...[
        pw.SizedBox(height: _Print.md),
        mark(InvoicePdfMarks.notes, _notes(notes, labels)),
      ],
      // Pushes the signatures to the bottom. When the content above grows
      // past the page, this shrinks to zero and the signatures are painted
      // below the margin, with no error. The budgets keep that from happening.
      pw.Spacer(),
      mark(InvoicePdfMarks.signatures, _signatures(invoice, labels, mark)),
    ],
  );
}

pw.Widget _header(PrintableInvoice invoice, InvoicePdfLabels labels) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(child: pw.Text(invoice.issuer, style: _strong, maxLines: InvoicePdfBudget.issuerLines)),
      pw.SizedBox(width: _Print.lg),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Text(labels.title, style: _title),
          pw.SizedBox(height: _Print.xs),
          _ltr(invoice.number, _body),
        ],
      ),
    ],
  );
}

pw.Widget _parties(PrintableInvoice invoice, InvoicePdfLabels labels, PdfMark mark) {
  final phone = invoice.customerPhone?.trim() ?? '';

  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Expanded(
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(labels.billTo, style: _caption),
            pw.SizedBox(height: _Print.xs),
            pw.Text(invoice.customer, style: _strong, maxLines: InvoicePdfBudget.customerLines),
            if (phone.isNotEmpty) ...[
              pw.SizedBox(height: _Print.xs),
              _ltr(phone, _body),
            ],
          ],
        ),
      ),
      pw.SizedBox(width: _Print.lg),
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          mark(InvoicePdfMarks.issuedAt, _labeled(labels.issued, _ltr(_date(invoice.issued), _body))),
          pw.SizedBox(height: _Print.xs),
          _labeled(labels.due, _ltr(_date(invoice.due), _body)),
        ],
      ),
    ],
  );
}

pw.Widget _payments(PrintableInvoice invoice, InvoicePdfLabels labels) {
  final all = invoice.payments;
  // The line budget: the newest rows, and one summary row for the rest.
  final shown = all.length <= InvoicePdfBudget.paymentRows
      ? all
      : all.sublist(all.length - (InvoicePdfBudget.paymentRows - 1));
  final earlier = all.sublist(0, all.length - shown.length);

  final lines = <pw.Widget>[
    if (earlier.isNotEmpty)
      _paymentLine(
        pw.Row(
          children: [
            pw.Text(labels.earlierPayments, style: _body),
            pw.SizedBox(width: _Print.xs),
            _ltr('(${earlier.length})', _body),
          ],
        ),
        earlier.fold(0, (sum, payment) => sum + payment.amountCents),
      ),
    for (final payment in shown)
      _paymentLine(
        pw.Row(
          children: [
            _ltr(_date(payment.date), _body),
            pw.SizedBox(width: _Print.sm),
            pw.Expanded(child: pw.Text(payment.method, style: _body, maxLines: 1)),
          ],
        ),
        payment.amountCents,
      ),
  ];

  return pw.Container(
    padding: const pw.EdgeInsets.all(_Print.md),
    decoration: pw.BoxDecoration(
      border: pw.Border.all(color: _Print.line, width: _Print.rule),
      borderRadius: pw.BorderRadius.circular(_Print.radius),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.stretch,
      children: [
        pw.Text(labels.payments, style: _caption),
        pw.SizedBox(height: _Print.sm),
        for (var i = 0; i < lines.length; i++) ...[
          if (i > 0) pw.SizedBox(height: _Print.xs),
          lines[i],
        ],
      ],
    ),
  );
}

pw.Widget _paymentLine(pw.Widget start, int amountCents) {
  return pw.Row(
    children: [
      pw.Expanded(child: start),
      pw.SizedBox(width: _Print.md),
      _ltr(formatMoney(amountCents), _body),
    ],
  );
}

pw.Widget _totals(PrintableInvoice invoice, InvoicePdfLabels labels) {
  pw.Widget line(String label, int cents, pw.TextStyle style) => pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(label, style: _caption),
          pw.SizedBox(width: _Print.md),
          _ltr(formatMoney(cents), style),
        ],
      );

  return pw.Align(
    alignment: pw.AlignmentDirectional.centerEnd,
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.end,
      children: [
        // Nothing paid yet: the balance is the total, one line says it.
        if (invoice.payments.isNotEmpty) ...[
          line(labels.total, invoice.totalCents, _body),
          pw.SizedBox(height: _Print.xs),
          line(labels.paid, invoice.paidCents, _body),
          pw.SizedBox(height: _Print.sm),
        ],
        line(labels.balance, invoice.totalCents - invoice.paidCents, _total),
      ],
    ),
  );
}

pw.Widget _notes(String notes, InvoicePdfLabels labels) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      pw.Text(labels.notes, style: _caption),
      pw.SizedBox(height: _Print.xs),
      pw.Text(notes, style: _body, maxLines: InvoicePdfBudget.notesLines),
    ],
  );
}

pw.Widget _signatures(PrintableInvoice invoice, InvoicePdfLabels labels, PdfMark mark) {
  return pw.Row(
    crossAxisAlignment: pw.CrossAxisAlignment.end,
    children: [
      pw.Expanded(
        child: _signatureSlot(
          labels.issuerSignature,
          stamp: mark(InvoicePdfMarks.stamp, _stamp(invoice.sealName ?? invoice.issuer)),
        ),
      ),
      pw.SizedBox(width: _Print.xl),
      pw.Expanded(child: _signatureSlot(labels.customerSignature)),
    ],
  );
}

pw.Widget _signatureSlot(String label, {pw.Widget? stamp}) {
  final slot = pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
    children: [
      pw.SizedBox(height: _Print.signingSpace),
      pw.Divider(height: _Print.rule, thickness: _Print.rule, color: _Print.ink),
      pw.SizedBox(height: _Print.xs),
      pw.Text(label, style: _caption),
    ],
  );
  if (stamp == null) return slot;

  // The stamp belongs to this slot: positioned inside it, it moves with the
  // signatures. Placed at a fraction of the page (pw.Alignment(0.6, 0.7) in
  // a page-level Stack) it stays put while the content moves, and lands on
  // text as soon as the header grows.
  return pw.Stack(
    children: [
      slot,
      pw.PositionedDirectional(top: 0, end: _Print.md, child: stamp),
    ],
  );
}

pw.Widget _stamp(String name) {
  return pw.Transform.rotate(
    angle: -0.2,
    child: pw.Container(
      width: _Print.stamp,
      height: _Print.stamp,
      alignment: pw.Alignment.center,
      padding: const pw.EdgeInsets.all(_Print.sm),
      decoration: pw.BoxDecoration(
        shape: pw.BoxShape.circle,
        border: pw.Border.all(color: _Print.stampInk, width: 1.5),
      ),
      child: pw.Text(
        name,
        textAlign: pw.TextAlign.center,
        maxLines: 3,
        style: const pw.TextStyle(fontSize: _Print.stampText, color: _Print.stampInk, fontWeight: pw.FontWeight.bold),
      ),
    ),
  );
}

/// "Label  value" on one line; the value is usually an LTR run.
pw.Widget _labeled(String label, pw.Widget value) {
  return pw.Row(
    mainAxisSize: pw.MainAxisSize.min,
    children: [
      pw.Text(label, style: _caption),
      pw.SizedBox(width: _Print.sm),
      value,
    ],
  );
}

/// An LTR run (number, date, phone, amount): its own `pw.Text` in an LTR
/// `pw.Directionality`. Unicode isolates (U+2066/U+2069) print as boxes.
pw.Widget _ltr(String text, pw.TextStyle style) {
  return pw.Directionality(
    textDirection: pw.TextDirection.ltr,
    child: pw.Text(text, style: style),
  );
}

String _date(DateTime date) => '${_two(date.day)}/${_two(date.month)}/${date.year}';

String _two(int value) => value.toString().padLeft(2, '0');

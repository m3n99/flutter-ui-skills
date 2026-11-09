// The printed documents the PDF test renders. THE ONLY PDF FILE TO EDIT PER
// PROJECT.
//
// 1. Imports: replace the `package:app/...` line with the project's document
//    builders and print theme.
// 2. For every document, at least: a typical case, a case with every
//    optional field empty, and the longest content the forms allow (longest
//    names, most rows, max-length notes, biggest amounts), in each direction
//    the app prints.
// 3. mustShow / mustNotOverlap / maxPages: what must survive on paper.
//
// The entries below render the plugin's example invoice, as used by its CI.

import 'package:app/examples/invoice_pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import 'pdf_harness.dart';

/// Loaded once: the same font family as the app.
final Future<pw.ThemeData> _printTheme = loadPrintTheme();

final DateTime _issued = DateTime(2026, 11, 8);

/// The longest input the form accepts: [max] characters.
String _atMax(String text, int max) => text.length <= max ? text : text.substring(0, max);

PrintableInvoice _typical({required bool arabic}) => PrintableInvoice(
      issuer: arabic ? 'استوديو أطلس للتصميم' : 'Atlas Design Studio',
      number: 'INV-1042',
      customer: arabic ? 'مقهى الميناء الأزرق' : 'Blue Harbor Café',
      customerPhone: '+962 79 555 0142',
      issued: _issued,
      due: DateTime(2026, 11, 22),
      totalCents: 84200,
      payments: [
        PrintedPayment(date: DateTime(2026, 11, 1), amountCents: 20000, method: arabic ? 'نقداً' : 'Cash'),
        PrintedPayment(date: DateTime(2026, 11, 5), amountCents: 15000, method: arabic ? 'حوالة بنكية' : 'Bank transfer'),
      ],
      notes: arabic
          ? 'شكراً لتعاملكم معنا. يرجى ذكر رقم الفاتورة عند التحويل.'
          : 'Thank you for your business. Please quote the invoice number with your transfer.',
    );

/// Every optional field empty: no phone, no payments, no notes.
PrintableInvoice _minimal({required bool arabic}) => PrintableInvoice(
      issuer: arabic ? 'استوديو أطلس للتصميم' : 'Atlas Design Studio',
      number: 'INV-1043',
      customer: arabic ? 'مخبز ريفربند' : 'Riverbend Bakery',
      issued: _issued,
      due: _issued,
      totalCents: 6400,
    );

/// The longest content the forms allow.
PrintableInvoice _longest({required bool arabic}) => PrintableInvoice(
      issuer: arabic
          ? 'شركة أطلس للتصميم والطباعة والخدمات الإعلانية المحدودة'
          : 'Atlas Design, Print and Advertising Services Company Limited',
      number: 'INV-2026-000123',
      customer: arabic
          ? 'مؤسسة لومن للطاقة الشمسية للتركيب والصيانة والخدمات الفنية'
          : 'Lumen Solar Installations and Maintenance Technical Services LLC',
      customerPhone: '+962 79 555 0142 / +962 6 555 0199',
      issued: _issued,
      due: DateTime(2027, 11, 8),
      totalCents: 999999999,
      // Monthly, December to November: all before the issue date.
      payments: [
        for (var i = 0; i < 12; i++)
          PrintedPayment(
            date: DateTime(2025, 12 + i, 5),
            amountCents: 41666600 + i,
            method: arabic ? 'حوالة بنكية - البنك العربي - فرع عبدون' : 'Bank transfer - Arab Bank, Abdoun branch',
          ),
      ],
      notes: _atMax(
        arabic
            ? 'يرجى تحويل المبلغ إلى الحساب المذكور أعلاه قبل تاريخ الاستحقاق وذكر رقم الفاتورة في وصف الحوالة. '
                'لأي استفسار يرجى التواصل مع قسم المحاسبة خلال ساعات الدوام الرسمي من الأحد إلى الخميس.'
            : 'Please transfer the amount to the account above before the due date and quote the invoice number '
                'in the transfer description. For questions, contact accounting Sunday to Thursday.',
        InvoicePdfBudget.notesMaxLength,
      ),
      // The legal name is too long for a seal; seals carry a short name.
      sealName: arabic ? 'أطلس للتصميم' : 'Atlas Design',
    );

const List<String> _mustShow = [
  InvoicePdfMarks.issuedAt,
  InvoicePdfMarks.totals,
  InvoicePdfMarks.signatures,
  InvoicePdfMarks.stamp,
];

const List<(String, String)> _stampClear = [
  (InvoicePdfMarks.stamp, InvoicePdfMarks.issuedAt),
  (InvoicePdfMarks.stamp, InvoicePdfMarks.payments),
  (InvoicePdfMarks.stamp, InvoicePdfMarks.totals),
  (InvoicePdfMarks.stamp, InvoicePdfMarks.notes),
];

final List<PdfCase> pdfCases = [
  for (final (language, labels) in [('ar', InvoicePdfLabels.ar), ('en', InvoicePdfLabels.en)])
    for (final (variant, data) in [
      ('typical', _typical(arabic: language == 'ar')),
      ('minimal', _minimal(arabic: language == 'ar')),
      ('longest', _longest(arabic: language == 'ar')),
    ])
      PdfCase(
        'invoice_${language}_$variant',
        (mark) async => buildInvoicePdf(data, theme: await _printTheme, labels: labels, mark: mark),
        mustShow: _mustShow,
        mustNotOverlap: _stampClear,
        maxPages: 1,
      ),
];

// In-memory sample domain for the example screens: invoices with a status
// model that maps every status to one label, one icon and one tone.

import 'dart:async';

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

enum InvoiceStatus { draft, sent, dueSoon, overdue, paid }

/// The single place where a status becomes UI: never color alone.
extension InvoiceStatusUi on InvoiceStatus {
  String get label => switch (this) {
        InvoiceStatus.draft => 'Draft',
        InvoiceStatus.sent => 'Sent',
        InvoiceStatus.dueSoon => 'Due soon',
        InvoiceStatus.overdue => 'Overdue',
        InvoiceStatus.paid => 'Paid',
      };

  IconData get icon => switch (this) {
        InvoiceStatus.draft => Icons.edit_note_rounded,
        InvoiceStatus.sent => Icons.send_rounded,
        InvoiceStatus.dueSoon => Icons.schedule_rounded,
        InvoiceStatus.overdue => Icons.error_outline_rounded,
        InvoiceStatus.paid => Icons.check_circle_outline_rounded,
      };

  StatusTone get tone => switch (this) {
        InvoiceStatus.draft => StatusTone.neutral,
        InvoiceStatus.sent => StatusTone.info,
        InvoiceStatus.dueSoon => StatusTone.warning,
        InvoiceStatus.overdue => StatusTone.danger,
        InvoiceStatus.paid => StatusTone.success,
      };

  StatusPill get pill => StatusPill(label: label, icon: icon, tone: tone);
}

@immutable
class Invoice {
  const Invoice({
    required this.id,
    required this.number,
    required this.customer,
    required this.amountCents,
    required this.due,
    required this.status,
  });

  final int id;
  final String number;
  final String customer;

  /// Money is stored in minor units, never as a double.
  final int amountCents;
  final DateTime due;
  final InvoiceStatus status;

  bool get isOpen => status != InvoiceStatus.paid && status != InvoiceStatus.draft;
}

/// Fixed "today" so screenshots are reproducible.
final DateTime sampleToday = DateTime(2026, 11, 8);

const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

String formatShortDate(DateTime date) => '${_months[date.month - 1]} ${date.day}';

/// `$12,480.50`. Real apps use `intl`'s NumberFormat with the user's locale.
String formatMoney(int cents) {
  final negative = cents < 0;
  final abs = cents.abs();
  final whole = (abs ~/ 100).toString();
  final buffer = StringBuffer();
  for (var i = 0; i < whole.length; i++) {
    if (i > 0 && (whole.length - i) % 3 == 0) buffer.write(',');
    buffer.write(whole[i]);
  }
  final fraction = (abs % 100).toString().padLeft(2, '0');
  return '${negative ? '-' : ''}\$$buffer.$fraction';
}

class InvoiceRepository {
  InvoiceRepository({this.latency = const Duration(milliseconds: 700)}) : _hang = false; // lint-ui: ok (fake network)

  /// A repository whose loads never finish (no pending timers): renders the
  /// loading state in tests and screenshots.
  InvoiceRepository.loadingForever()
      : latency = Duration.zero,
        _hang = true;

  final Duration latency;
  final bool _hang;

  /// Makes the next load fail once (error-state screenshots, retry demos).
  bool failNextLoad = false;

  int _nextId = 1043;

  final List<Invoice> _invoices = [
    Invoice(id: 1042, number: 'INV-1042', customer: 'Blue Harbor Café', amountCents: 84200, due: DateTime(2026, 11, 10), status: InvoiceStatus.dueSoon),
    Invoice(id: 1041, number: 'INV-1041', customer: 'Kinetic Labs', amountCents: 1250000, due: DateTime(2026, 11, 2), status: InvoiceStatus.overdue),
    Invoice(id: 1040, number: 'INV-1040', customer: 'Olive & Thyme Bistro', amountCents: 39000, due: DateTime(2026, 11, 12), status: InvoiceStatus.dueSoon),
    Invoice(id: 1039, number: 'INV-1039', customer: 'Atlas Field Services', amountCents: 248050, due: DateTime(2026, 11, 20), status: InvoiceStatus.sent),
    Invoice(id: 1038, number: 'INV-1038', customer: 'Sunrise Dental Clinic', amountCents: 95000, due: DateTime(2026, 10, 30), status: InvoiceStatus.paid),
    Invoice(id: 1037, number: 'INV-1037', customer: 'Cedar Print Co.', amountCents: 17550, due: DateTime(2026, 10, 28), status: InvoiceStatus.overdue),
    Invoice(id: 1036, number: 'INV-1036', customer: 'Mosaic Studio', amountCents: 412000, due: DateTime(2026, 11, 25), status: InvoiceStatus.sent),
    Invoice(id: 1035, number: 'INV-1035', customer: 'Lumen Solar Installations and Maintenance', amountCents: 2890000, due: DateTime(2026, 10, 15), status: InvoiceStatus.paid),
    Invoice(id: 1034, number: 'INV-1034', customer: 'Riverbend Bakery', amountCents: 6400, due: DateTime(2026, 12, 1), status: InvoiceStatus.draft),
    Invoice(id: 1033, number: 'INV-1033', customer: 'Pinecrest Realty', amountCents: 156000, due: DateTime(2026, 10, 5), status: InvoiceStatus.paid),
  ];

  /// Collected per month, Jun–Nov, in cents.
  static const List<int> collectedByMonth = [820000, 960000, 740000, 1120000, 1040000, 1248050];
  static const List<String> monthLabels = ['Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov'];
  static const List<String> monthNumbers = ['6', '7', '8', '9', '10', '11'];

  Future<List<Invoice>> load() async {
    if (_hang) return Completer<List<Invoice>>().future;
    await Future<void>.delayed(latency);
    if (failNextLoad) {
      failNextLoad = false;
      throw StateError('Network unavailable');
    }
    return List<Invoice>.unmodifiable(_invoices);
  }

  Future<void> delete(int id) async {
    await Future<void>.delayed(latency ~/ 2);
    _invoices.removeWhere((invoice) => invoice.id == id);
  }

  Future<Invoice> update(int id, {required String customer, required int amountCents, required DateTime due}) async {
    await Future<void>.delayed(latency);
    final index = _invoices.indexWhere((invoice) => invoice.id == id);
    final old = _invoices[index];
    final invoice = Invoice(
      id: id,
      number: old.number,
      customer: customer,
      amountCents: amountCents,
      due: due,
      status: old.status,
    );
    _invoices[index] = invoice;
    return invoice;
  }

  Future<Invoice> create({required String customer, required int amountCents, required DateTime due}) async {
    await Future<void>.delayed(latency);
    final id = _nextId++;
    final invoice = Invoice(
      id: id,
      number: 'INV-$id',
      customer: customer,
      amountCents: amountCents,
      due: due,
      status: InvoiceStatus.sent,
    );
    _invoices.insert(0, invoice);
    return invoice;
  }
}

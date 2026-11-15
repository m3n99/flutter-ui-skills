// The home screen's words, in English and in Arabic.
//
// A real app keeps these in ARB files and generates the class with gen-l10n
// (references/rtl-arabic.md). The example keeps two small tables instead, so
// it needs no localization package, and picks one by the reading direction:
// the right-to-left screenshots then show real Arabic, with its own plural
// forms, month names and word order, and not English mirrored.
//
// What the Arabic table shows (references/writing.md › Arabic interfaces):
// - buttons are verbal nouns ("إرسال تذكيرين"), not imperatives;
// - counts follow the six plural forms: one, two (the dual, with no digit),
//   3 to 10, 11 and up; "2 فواتير" is wrong, "فاتورتان" is right;
// - a change is said in words ("أعلى بـ 20% من…"): a leading "+" would jump
//   to the far side of the number in right-to-left text;
// - months are the names the audience uses (Levantine here), in full:
//   Arabic has no "Nov".

import 'package:flutter/widgets.dart';

import 'sample_data.dart';

abstract class HomeStrings {
  const HomeStrings();

  static HomeStrings of(BuildContext context) =>
      Directionality.of(context) == TextDirection.rtl ? const _Arabic() : const _English();

  String get title;
  String get toCollect;
  String get overdue;
  String get dueThisWeek;
  String get later;
  String invoices(int count);
  String sendReminders(int count);
  String sentReminderTo(String customer);
  String sentReminders(int count);
  String get collectedThisMonth;
  String get comparedWithLastMonth;
  String get openInvoices;

  /// Null when there are none: the tile then shows no caption.
  String? draftsNotSent(int count);
  String get collectedPerMonth;
  String get lastSixMonths;
  List<String> get chartMonths;
  String get chartDescription;
  String get dueSoon;
  String get seeAll;
  String due(DateTime date);
  String status(InvoiceStatus status);
  String get nothingDueTitle;
  String get nothingDueMessage;
  String get loadFailedTitle;
  String get loadFailedMessage;
  String get retry;
}

class _English extends HomeStrings {
  const _English();

  @override
  String get title => 'Overview';
  @override
  String get toCollect => 'To collect';
  @override
  String get overdue => 'Overdue';
  @override
  String get dueThisWeek => 'Due this week';
  @override
  String get later => 'Later';
  @override
  String invoices(int count) => count == 1 ? '1 invoice' : '$count invoices';
  @override
  String sendReminders(int count) => count == 1 ? 'Send 1 reminder' : 'Send $count reminders';
  @override
  String sentReminderTo(String customer) => 'Sent a reminder to $customer';
  @override
  String sentReminders(int count) => 'Sent $count reminders';
  @override
  String get collectedThisMonth => 'Collected in November';
  @override
  String get comparedWithLastMonth => '+20% vs October';
  @override
  String get openInvoices => 'Open invoices';
  @override
  String? draftsNotSent(int count) => switch (count) {
        0 => null,
        1 => '1 draft not sent yet',
        _ => '$count drafts not sent yet',
      };
  @override
  String get collectedPerMonth => 'Collected per month';
  @override
  String get lastSixMonths => 'Last 6 months';
  @override
  List<String> get chartMonths => InvoiceRepository.monthLabels;
  @override
  String get chartDescription => 'Collected per month, June to November, highest in November.';
  @override
  String get dueSoon => 'Due soon';
  @override
  String get seeAll => 'See all';
  @override
  String due(DateTime date) => 'Due ${formatShortDate(date)}';
  @override
  String status(InvoiceStatus status) => status.label;
  @override
  String get nothingDueTitle => 'Nothing due this week';
  @override
  String get nothingDueMessage => 'Invoices due in the next 7 days show up here.';
  @override
  String get loadFailedTitle => "Couldn't load your overview";
  @override
  String get loadFailedMessage => 'Check your connection and try again.';
  @override
  String get retry => 'Retry';
}

class _Arabic extends HomeStrings {
  const _Arabic();

  static const List<String> _months = [
    'كانون الثاني',
    'شباط',
    'آذار',
    'نيسان',
    'أيار',
    'حزيران',
    'تموز',
    'آب',
    'أيلول',
    'تشرين الأول',
    'تشرين الثاني',
    'كانون الأول',
  ];

  /// One, two, 3 to 10, then 11 and up (which also covers the hundreds).
  static String _plural(int count, {required String one, required String two, required String few, required String many}) {
    final lastTwo = count % 100;
    if (count == 1) return one;
    if (count == 2) return two;
    if (lastTwo >= 3 && lastTwo <= 10) return few;
    return many;
  }

  @override
  String get title => 'نظرة عامة';
  @override
  String get toCollect => 'للتحصيل';
  @override
  String get overdue => 'متأخرة';
  @override
  String get dueThisWeek => 'تستحق هذا الأسبوع';
  @override
  String get later => 'لاحقًا';
  @override
  String invoices(int count) => count == 0
      ? 'لا فواتير'
      : _plural(count, one: 'فاتورة واحدة', two: 'فاتورتان', few: '$count فواتير', many: '$count فاتورة');
  @override
  String sendReminders(int count) => _plural(
        count,
        one: 'إرسال تذكير',
        two: 'إرسال تذكيرين',
        few: 'إرسال $count تذكيرات',
        many: 'إرسال $count تذكيرًا',
      );
  @override
  String sentReminderTo(String customer) => 'تم إرسال تذكير إلى $customer';
  @override
  String sentReminders(int count) => _plural(
        count,
        one: 'تم إرسال تذكير واحد',
        two: 'تم إرسال تذكيرين',
        few: 'تم إرسال $count تذكيرات',
        many: 'تم إرسال $count تذكيرًا',
      );
  @override
  String get collectedThisMonth => 'المحصّل في تشرين الثاني';
  @override
  String get comparedWithLastMonth => 'أعلى بـ 20% من تشرين الأول';
  @override
  String get openInvoices => 'فواتير مفتوحة';
  @override
  String? draftsNotSent(int count) => count == 0
      ? null
      : _plural(
          count,
          one: 'مسودة واحدة لم تُرسل',
          two: 'مسودتان لم تُرسلا',
          few: '$count مسودات لم تُرسل',
          many: '$count مسودة لم تُرسل',
        );
  @override
  String get collectedPerMonth => 'التحصيل الشهري';
  @override
  String get lastSixMonths => 'آخر 6 أشهر';
  @override
  List<String> get chartMonths => _months.sublist(5, 11);
  @override
  String get chartDescription => 'التحصيل الشهري من حزيران إلى تشرين الثاني، والأعلى في تشرين الثاني.';
  @override
  String get dueSoon => 'تستحق قريبًا';
  @override
  String get seeAll => 'عرض الكل';
  @override
  String due(DateTime date) => 'تستحق في ${date.day} ${_months[date.month - 1]}';
  @override
  String status(InvoiceStatus status) => switch (status) {
        InvoiceStatus.draft => 'مسودة',
        InvoiceStatus.sent => 'مُرسلة',
        InvoiceStatus.dueSoon => 'تستحق قريبًا',
        InvoiceStatus.overdue => 'متأخرة',
        InvoiceStatus.paid => 'مدفوعة',
      };
  @override
  String get nothingDueTitle => 'لا فواتير تستحق هذا الأسبوع';
  @override
  String get nothingDueMessage => 'تظهر هنا الفواتير التي تستحق خلال 7 أيام.';
  @override
  String get loadFailedTitle => 'تعذّر تحميل النظرة العامة';
  @override
  String get loadFailedMessage => 'يُرجى التحقق من الاتصال والمحاولة مرة أخرى.';
  @override
  String get retry => 'إعادة المحاولة';
}

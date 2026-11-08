import 'package:flutter/widgets.dart';

/// Keeps numbers, phone numbers, IDs, dates and amounts left-to-right inside
/// right-to-left layouts, so `0599-123456` never renders as `123456-0599`.
///
/// Wrap the smallest widget that holds the value (the Text itself): inside
/// this widget `start` means left again.
class Ltr extends StatelessWidget {
  const Ltr({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => Directionality(textDirection: TextDirection.ltr, child: child);
}

/// Wraps [text] in Unicode left-to-right isolates (U+2066 ... U+2069) for use
/// inside a longer RTL string: `'تستحق ${ltr('07/12/2026')}'`.
///
/// Works in Flutter widgets. Does NOT work in the `pdf` package, where the
/// isolates render as boxes and nothing is reordered: put the LTR run in its
/// own `pw.Text` inside `pw.Directionality(textDirection: pw.TextDirection.ltr)`.
String ltr(String text) => '\u2066$text\u2069';

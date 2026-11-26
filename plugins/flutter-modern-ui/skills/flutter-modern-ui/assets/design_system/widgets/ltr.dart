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

/// Keeps a value in one piece when its line wraps. Isolates and [Ltr] fix
/// the order of a left-to-right run, not where a line breaks: at 360 px
/// «4–6» split into «4–» / «6», and an amount left its «₪» behind.
///
/// - spaces become no-break spaces (U+00A0): «3,000.50 ₪», «× 500»;
/// - a dash, «/» and «×» get word joiners (U+2060) on both sides: «4–6».
///
/// For a list of such values in Arabic text, one `Text` each in a `Wrap`
/// (the `Wrap` gives the reading order, lines break only between pieces)
/// beats one joined string. Flutter text only: the `pdf` package draws
/// U+2060 as a box; there, one `pw.Text` per piece in a `pw.Wrap`.
String keepTogether(String text) =>
    text.replaceAll(' ', '\u00A0').replaceAllMapped(RegExp(r'[-–—/×]'), (match) => '\u2060${match[0]}\u2060');

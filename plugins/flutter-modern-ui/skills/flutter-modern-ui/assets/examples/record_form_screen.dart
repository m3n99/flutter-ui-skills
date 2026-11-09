// Reference composition: a long form. Shows:
// - sections as cards, labels above fields, helper and error text;
// - the save bar as the LAST CHILD OF THE BODY COLUMN (not
//   Scaffold.bottomNavigationBar, which the keyboard covers), so it stays
//   above the keyboard;
// - money input stored in minor units, accepting Arabic-Indic and Persian
//   digits and `.`, `,` or `٫` as the decimal separator; LTR inside RTL;
// - a warning-level hint (non-blocking) next to blocking validation;
// - a few single-choice options (payment terms) as a wrapping chip row with
//   an inline label, never a scrolling one, so all of them stay visible on a
//   phone; the choice is derived from the due date it sets;
// - a text cap shared with the printed document (InvoicePdfBudget), so the
//   form never accepts more than the page can hold;
// - validation after the first submit, a shake on a failed submit, and a
//   SubmitButton that shows progress and can't be pressed twice;
// - the success message names the thing that was created.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../design_system/design_system.dart';
import 'invoice_pdf.dart' show InvoicePdfBudget;
import 'sample_data.dart';

/// Normalizes Arabic-Indic (٠-٩) and Persian (۰-۹) digits to 0-9, accepts one
/// decimal separator (`.`, `,` or `٫`, stored as `.`) and at most 2 decimals.
class MoneyInputFormatter extends TextInputFormatter {
  const MoneyInputFormatter();

  static const String _arabicIndic = '٠١٢٣٤٥٦٧٨٩';
  static const String _persian = '۰۱۲۳۴۵۶۷۸۹';

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    final buffer = StringBuffer();
    var separator = false;
    var decimals = 0;
    for (final unit in newValue.text.split('')) {
      var c = unit;
      final arabic = _arabicIndic.indexOf(c);
      if (arabic >= 0) c = '$arabic';
      final persian = _persian.indexOf(c);
      if (persian >= 0) c = '$persian';

      if (c == '.' || c == ',' || c == '٫') {
        if (!separator) {
          separator = true;
          buffer.write('.');
        }
      } else if (c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39) {
        if (separator) {
          if (decimals == 2) continue;
          decimals++;
        }
        buffer.write(c);
      }
    }
    final text = buffer.toString();
    return TextEditingValue(text: text, selection: TextSelection.collapsed(offset: text.length));
  }
}

/// "1250.5" → 125050. Null when empty or not a number.
int? parseCents(String text) {
  if (text.isEmpty) return null;
  final parts = text.split('.');
  final whole = int.tryParse(parts.first.isEmpty ? '0' : parts.first);
  if (whole == null) return null;
  final fraction = parts.length > 1 ? parts[1].padRight(2, '0').substring(0, 2) : '00';
  final cents = int.tryParse(fraction);
  return cents == null ? null : whole * 100 + cents;
}

/// Payment terms: three single-choice options.
enum _Terms {
  onReceipt(0, 'Due on receipt'),
  net14(14, 'Net 14'),
  net30(30, 'Net 30');

  const _Terms(this.days, this.label);

  final int days;
  final String label;
}

class RecordFormScreen extends StatefulWidget {
  const RecordFormScreen({super.key, required this.repository});

  final InvoiceRepository repository;

  @override
  State<RecordFormScreen> createState() => _RecordFormScreenState();
}

class _RecordFormScreenState extends State<RecordFormScreen> {
  static const int _largeAmountCents = 1000000;

  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _customer = TextEditingController();
  final TextEditingController _email = TextEditingController();
  final TextEditingController _amount = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  DateTime _due = sampleToday.add(const Duration(days: 14));
  late final TextEditingController _dueText = TextEditingController(text: formatShortDate(_due));
  bool _submitted = false;
  int _failedSubmits = 0;

  @override
  void dispose() {
    _customer.dispose();
    _email.dispose();
    _amount.dispose();
    _notes.dispose();
    _dueText.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _due,
      firstDate: sampleToday,
      lastDate: sampleToday.add(const Duration(days: 365)),
    );
    if (picked == null || !mounted) return;
    _setDue(picked);
  }

  void _setDue(DateTime due) {
    setState(() {
      _due = due;
      _dueText.text = formatShortDate(due);
    });
  }

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (!(_formKey.currentState?.validate() ?? false)) {
      setState(() => _failedSubmits++);
      return;
    }
    try {
      final invoice = await widget.repository.create(
        customer: _customer.text.trim(),
        amountCents: parseCents(_amount.text) ?? 0,
        due: _due,
      );
      if (!mounted) return;
      AppMessenger.success('Created ${invoice.number} for ${invoice.customer}');
      Navigator.of(context).pop(invoice);
    } catch (failure) {
      AppMessenger.showFailure(
        failure,
        whatFailed: "Couldn't save the invoice. Your changes are still here; try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final dueInDays = _due.difference(sampleToday).inDays;

    return Scaffold(
      appBar: AppBar(title: const Text('New invoice')),
      body: LayoutBuilder(
        builder: (context, box) {
          final side = ContentWidth.horizontalPadding(box.maxWidth, maxWidth: AppSize.formMaxWidth);
          return Column(
            children: [
              Expanded(
                child: Form(
                  key: _formKey,
                  autovalidateMode: _submitted ? AutovalidateMode.onUserInteraction : AutovalidateMode.disabled,
                  // SingleChildScrollView + Column, not ListView: a lazy list
                  // unmounts off-screen fields, which then skip validation.
                  child: SingleChildScrollView(
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, AppSpace.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                      _FormSection(
                        title: 'Customer',
                        children: [
                          _LabeledField(
                            label: 'Bill to',
                            child: TextFormField(
                              controller: _customer,
                              textInputAction: TextInputAction.next,
                              textCapitalization: TextCapitalization.words,
                              autofillHints: const [AutofillHints.organizationName],
                              decoration: const InputDecoration(hintText: 'Company or person'),
                              validator: (value) =>
                                  value == null || value.trim().isEmpty ? 'Enter who the invoice is for.' : null,
                            ),
                          ),
                          _LabeledField(
                            label: 'Email',
                            child: TextFormField(
                              controller: _email,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              textDirection: TextDirection.ltr,
                              autofillHints: const [AutofillHints.email],
                              decoration: const InputDecoration(
                                hintText: 'billing@example.com',
                                helperText: 'Optional. The invoice is sent here.',
                              ),
                              validator: (value) {
                                final email = value?.trim() ?? '';
                                if (email.isEmpty) return null;
                                return email.contains('@') && email.contains('.') ? null : 'Enter an email like name@example.com.';
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      _FormSection(
                        title: 'Amount',
                        children: [
                          _LabeledField(
                            label: 'Total',
                            child: ValueListenableBuilder<TextEditingValue>(
                              valueListenable: _amount,
                              builder: (context, value, _) {
                                final large = (parseCents(value.text) ?? 0) >= _largeAmountCents;
                                return TextFormField(
                                  controller: _amount,
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  textInputAction: TextInputAction.next,
                                  textDirection: TextDirection.ltr,
                                  inputFormatters: const [MoneyInputFormatter()],
                                  style: text.bodyLarge.tabular,
                                  decoration: InputDecoration(
                                    prefixText: '\$ ',
                                    hintText: '0.00',
                                    // Warning, not error: the user can still save.
                                    helperText: large ? 'Larger than usual. Double-check before sending.' : null,
                                    helperStyle: large ? text.bodySmall?.copyWith(color: context.palette.warning.color) : null,
                                    helperMaxLines: 2,
                                  ),
                                  validator: (value) => (parseCents(value ?? '') ?? 0) <= 0 ? 'Enter an amount above zero.' : null,
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      _FormSection(
                        title: 'Dates',
                        children: [
                          // Three options: wrap with the label inline, so every
                          // choice stays on screen at 360 px and text scale 1.3.
                          AppChoiceChips<_Terms>(
                            label: 'Terms',
                            options: _Terms.values,
                            // Derived from the due date: a date picked by hand
                            // clears the choice.
                            selected: {
                              for (final terms in _Terms.values)
                                if (terms.days == dueInDays) terms,
                            },
                            labelOf: (terms) => terms.label,
                            onToggle: (terms) => _setDue(sampleToday.add(Duration(days: terms.days))),
                          ),
                          _LabeledField(
                            label: 'Due date',
                            child: TextFormField(
                              controller: _dueText,
                              readOnly: true,
                              onTap: _pickDue,
                              enableInteractiveSelection: false,
                              mouseCursor: SystemMouseCursors.click,
                              style: text.bodyLarge.tabular,
                              decoration: InputDecoration(
                                suffixIcon: const Icon(Icons.calendar_today_rounded),
                                // Live summary of the choice.
                                helperText: switch (dueInDays) {
                                  0 => 'Due today',
                                  1 => 'Due tomorrow',
                                  _ => 'Due in $dueInDays days',
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.md),
                      _FormSection(
                        title: 'Notes',
                        children: [
                          TextFormField(
                            controller: _notes,
                            minLines: 3,
                            maxLines: 6,
                            // What the printed invoice's notes box holds.
                            maxLength: InvoicePdfBudget.notesMaxLength,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: InputDecoration(
                              hintText: 'Payment terms, bank details, thank-you note…',
                              hintStyle: text.bodyLarge?.copyWith(color: colors.onSurfaceVariant),
                            ),
                          ),
                        ],
                      ),
                      ],
                    ),
                  ),
                ),
              ),
              _SaveBar(
                horizontalPadding: side,
                child: ShakeOnChange(
                  trigger: _failedSubmits,
                  child: SubmitButton(label: 'Create invoice', icon: Icons.check_rounded, onPressed: _save),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _FormSection extends StatelessWidget {
  const _FormSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          Text(title, style: context.textStyles.titleMedium),
          ...children,
        ],
      ),
    );
  }
}

/// Label above the field: floating labels read as dated in most modern UIs.
class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: AppSpace.xs,
      children: [
        Text(label, style: context.textStyles.titleSmall),
        child,
      ],
    );
  }
}

/// Pinned footer: hairline on top, safe area at the bottom. Because it is
/// the last child of the body Column, the Scaffold lifts it above the
/// keyboard.
class _SaveBar extends StatelessWidget {
  const _SaveBar({required this.child, required this.horizontalPadding});

  final Widget child;
  final double horizontalPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(top: BorderSide(color: colors.outlineVariant)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: AppSpace.sm),
          child: SizedBox(width: double.infinity, child: child),
        ),
      ),
    );
  }
}

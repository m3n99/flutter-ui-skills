// Reference composition for a settings page (references/screens.md ›
// Settings). Shows:
// - groups as cards under a heading, the most used group first;
// - the four kinds of row: a switch that applies at once, a pick-one that
//   shows its current value and opens a pick-one sheet, an action, and a
//   destructive action kept apart, last, in the error color;
// - no Save button: every change applies when it's made, and what changed is
//   visible in the row itself;
// - each language written in its own script;
// - narrow screens (big fonts, small phones): the current value moves under
//   the title instead of squeezing it;
// - typed confirmation for the one action that can't be undone;
// - rows inside a card use the concentric radius; the page is capped at form
//   width on wide windows and ends clear of the navigation bar.
//
// Presentation only: swap the local state for the project's settings store.

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

enum _Terms {
  onReceipt('Due on receipt'),
  net14('Net 14'),
  net30('Net 30');

  const _Terms(this.label);
  final String label;
}

enum _Currency {
  usd('US dollar (\$)'),
  eur('Euro (€)'),
  ils('Israeli shekel (₪)'),
  jod('Jordanian dinar (JD)');

  const _Currency(this.label);
  final String label;
}

enum _Language {
  english('English'),
  arabic('العربية');

  /// Each language in its own script, so its speakers can find it.
  const _Language(this.label);
  final String label;
}

extension on ThemeMode {
  String get label => switch (this) {
        ThemeMode.system => 'Same as the device',
        ThemeMode.light => 'Light',
        ThemeMode.dark => 'Dark',
      };

  IconData get icon => switch (this) {
        ThemeMode.system => Icons.brightness_auto_outlined,
        ThemeMode.light => Icons.light_mode_outlined,
        ThemeMode.dark => Icons.dark_mode_outlined,
      };
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  _Terms _terms = _Terms.net14;
  _Currency _currency = _Currency.usd;
  bool _dueReminders = true;
  bool _overdueReminders = false;
  ThemeMode _theme = ThemeMode.system;
  _Language _language = _Language.english;

  Future<void> _pick<T>({
    required String title,
    required List<T> options,
    required T selected,
    required String Function(T option) labelOf,
    IconData Function(T option)? iconOf,
    required ValueChanged<T> onPicked,
  }) async {
    final picked = await showAppPicker<T>(
      context: context,
      title: title,
      options: options,
      selected: selected,
      labelOf: labelOf,
      iconOf: iconOf,
    );
    if (picked == null || !mounted) return;
    setState(() => onPicked(picked));
  }

  Future<void> _deleteAll() async {
    final confirmed = await showDialog<bool>(context: context, builder: (context) => const _DeleteAllDialog());
    if (confirmed != true || !mounted) return;
    AppMessenger.success('Deleted all invoices');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: LayoutBuilder(
          builder: (context, box) {
            final side = ContentWidth.horizontalPadding(box.maxWidth, maxWidth: AppSize.formMaxWidth);
            return CustomScrollView(
              slivers: [
                // A plain title on the content's own start edge: with no
                // actions to hold, an app bar would be an empty row.
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, 0),
                  sliver: SliverToBoxAdapter(child: Text('Settings', style: context.textStyles.headlineSmall)),
                ),
                SliverPadding(
                  padding: EdgeInsetsDirectional.fromSTEB(side, AppSpace.md, side, context.listEndPadding()),
                  sliver: SliverList.list(
                    children: [
                      _SettingsGroup(
                        title: 'Invoices',
                        children: [
                          _PickRow(
                            icon: Icons.event_outlined,
                            title: 'Default terms',
                            value: _terms.label,
                            onTap: () => _pick<_Terms>(
                              title: 'Default terms',
                              options: _Terms.values,
                              selected: _terms,
                              labelOf: (terms) => terms.label,
                              onPicked: (terms) => _terms = terms,
                            ),
                          ),
                          _PickRow(
                            icon: Icons.payments_outlined,
                            title: 'Currency',
                            value: _currency.label,
                            onTap: () => _pick<_Currency>(
                              title: 'Currency',
                              options: _Currency.values,
                              selected: _currency,
                              labelOf: (currency) => currency.label,
                              onPicked: (currency) => _currency = currency,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      _SettingsGroup(
                        title: 'Reminders',
                        children: [
                          _SwitchRow(
                            icon: Icons.notifications_none_rounded,
                            title: 'Due-date reminders',
                            subtitle: 'The day before an invoice is due',
                            value: _dueReminders,
                            onChanged: (value) => setState(() => _dueReminders = value),
                          ),
                          _SwitchRow(
                            icon: Icons.notifications_active_outlined,
                            title: 'Overdue reminders',
                            subtitle: 'Every Monday, for invoices past due',
                            value: _overdueReminders,
                            onChanged: (value) => setState(() => _overdueReminders = value),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      _SettingsGroup(
                        title: 'Appearance',
                        children: [
                          _PickRow(
                            icon: _theme.icon,
                            title: 'Theme',
                            value: _theme.label,
                            onTap: () => _pick<ThemeMode>(
                              title: 'Theme',
                              options: ThemeMode.values,
                              selected: _theme,
                              labelOf: (mode) => mode.label,
                              iconOf: (mode) => mode.icon,
                              onPicked: (mode) => _theme = mode,
                            ),
                          ),
                          _PickRow(
                            icon: Icons.language_rounded,
                            title: 'Language',
                            value: _language.label,
                            onTap: () => _pick<_Language>(
                              title: 'Language',
                              options: _Language.values,
                              selected: _language,
                              labelOf: (language) => language.label,
                              onPicked: (language) => _language = language,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      _SettingsGroup(
                        title: 'Data',
                        children: [
                          _ActionRow(
                            icon: Icons.download_outlined,
                            title: 'Export invoices',
                            subtitle: 'A spreadsheet of every invoice and payment',
                            onTap: () => AppMessenger.success('Exported 12 invoices to Downloads'),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      // Apart from the rest, last, and it confirms.
                      _SettingsGroup(
                        title: 'Danger zone',
                        children: [
                          _ActionRow(
                            icon: Icons.delete_forever_outlined,
                            title: 'Delete all invoices',
                            subtitle: "Removes every invoice from this device. Can't be undone.",
                            destructive: true,
                            onTap: _deleteAll,
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.lg),
                      Center(
                        child: Ltr(
                          child: Text(
                            'Version 2.4.1 (118)',
                            style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// A heading over one card. The rows sit 8 px inside the card, so their
/// ink radius is the card's minus 8 (concentric).
class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.xs,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: AppSpace.xs),
          child: Semantics(
            header: true,
            child: Text(
              title,
              style: context.textStyles.titleSmall?.copyWith(color: context.colors.onSurfaceVariant),
            ),
          ),
        ),
        AppCard(
          padding: const EdgeInsets.all(AppSpace.xs),
          child: Column(children: children),
        ),
      ],
    );
  }
}

ShapeBorder _rowShape() => RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.concentric(AppRadius.card, AppSpace.xs)),
    );

const EdgeInsetsGeometry _rowPadding = EdgeInsets.symmetric(horizontal: AppSpace.sm);

/// A choice among a few: the row shows the current one and opens a pick-one
/// sheet. The value sits at the end, or under the title when the screen is
/// narrow for its text.
class _PickRow extends StatelessWidget {
  const _PickRow({required this.icon, required this.title, required this.value, required this.onTap});

  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = context.isNarrow;
    final muted = context.textStyles.bodyMedium?.copyWith(color: context.colors.onSurfaceVariant);

    return ListTile(
      shape: _rowShape(),
      contentPadding: _rowPadding,
      leading: Icon(icon),
      title: Text(title),
      subtitle: narrow ? Text(value) : null,
      trailing: narrow ? null : Text(value, style: muted),
      onTap: onTap,
    );
  }
}

/// On or off, applied at once: no Save. The label names what is on.
class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile.adaptive(
      shape: _rowShape(),
      contentPadding: _rowPadding,
      secondary: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Does something when tapped (export, sign out, delete).
class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.destructive = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.colors.error : null;

    return ListTile(
      shape: _rowShape(),
      contentPadding: _rowPadding,
      iconColor: color,
      textColor: color,
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onTap,
    );
  }
}

/// Deleting everything can't be undone, so the button stays off until the
/// word is typed (references/forms.md › Settings pages).
class _DeleteAllDialog extends StatefulWidget {
  const _DeleteAllDialog();

  @override
  State<_DeleteAllDialog> createState() => _DeleteAllDialogState();
}

class _DeleteAllDialogState extends State<_DeleteAllDialog> {
  static const String _word = 'DELETE';

  final TextEditingController _controller = TextEditingController();

  bool get _matches => _controller.text.trim().toUpperCase() == _word;

  void _confirm() {
    if (_matches) Navigator.of(context).pop(true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return AlertDialog(
      title: const Text('Delete all invoices?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: AppSpace.md,
        children: [
          const Text("This removes 12 invoices and their payments from this device. It can't be undone."),
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: AppSpace.xs,
            children: [
              Text('Type $_word to confirm', style: context.textStyles.titleSmall),
              TextField(
                controller: _controller,
                autofocus: true,
                autocorrect: false,
                textCapitalization: TextCapitalization.characters,
                textInputAction: TextInputAction.done,
                onChanged: (_) => setState(() {}),
                onSubmitted: (_) => _confirm(),
                decoration: const InputDecoration(hintText: _word),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text('Cancel')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError),
          onPressed: _matches ? _confirm : null,
          child: const Text('Delete all invoices'),
        ),
      ],
    );
  }
}

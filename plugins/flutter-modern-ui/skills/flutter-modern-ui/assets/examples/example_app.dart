// Wires the design system into an app: themes (light, dark, per-platform
// density), the single message component, and an adaptive shell whose tabs
// keep their state (IndexedStack also pauses tickers in hidden tabs, which
// MiniBarChart relies on).
//
// The example app's brief (references/identity.md), which every screen here
// is built from:
//   Subject    a small studio's invoice book: what was billed, who still
//              owes, what is late.
//   Audience   the owner; a minute on the phone each morning, the desktop
//              when billing.
//   Job        know what there is to collect and who to chase today.
//   Feeling    exact, calm, businesslike.
//   Signature  ledger lines: the label at the start, the figure in tabular
//              numerals at the end, ruled between. One shared widget
//              (ledger.dart), in three places: the home card, an invoice's
//              details, the sign-in mark.
//   Color      ink blue-black as the seed (fidelity), one accent, status
//              tones for money states.
//   Languages  English and Arabic. The home screen carries real Arabic
//              (home_strings.dart); Arabic text takes AppScript.arabic.
// So the home screen opens on "To collect" with the reminder action, not on
// a greeting over a grid of numbers.
//
// The tabs of an IndexedStack shell share one route, so their FABs need
// `heroTag: null` (or unique tags): two default tags throw "multiple heroes
// that share the same tag" as soon as any route is pushed. The UI tests
// render ExampleShell and push a route to catch exactly that.
//
// Run it: `void main() => runApp(const ExampleApp());`

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'dashboard_screen.dart';
import 'records_screen.dart';
import 'sample_data.dart';
import 'settings_screen.dart';

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, this.config = AppTheme.config});

  final AppThemeConfig config;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final InvoiceRepository _repository = InvoiceRepository();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Daybook',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(config: widget.config),
      darkTheme: AppTheme.dark(config: widget.config),
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: AppMessenger.key,
      // A bilingual app rebuilds its theme for the script it shows
      // (references/theming.md): Arabic takes zero letter-spacing and taller
      // lines. The reading direction stands for the locale here.
      builder: (context, child) => ArabicTypeInRtl(config: widget.config, child: child ?? const SizedBox.shrink()),
      home: ExampleShell(repository: _repository),
    );
  }
}

/// Gives its subtree the Arabic type scale (AppScript.arabic) when the
/// reading direction is right-to-left, and leaves it alone otherwise.
class ArabicTypeInRtl extends StatelessWidget {
  const ArabicTypeInRtl({super.key, required this.child, this.config = AppTheme.config});

  final Widget child;
  final AppThemeConfig config;

  @override
  Widget build(BuildContext context) {
    if (Directionality.of(context) != TextDirection.rtl) return child;
    final theme = Theme.of(context);
    return Theme(
      data: AppTheme.build(
        theme.brightness,
        platform: theme.platform,
        config: config.copyWith(script: AppScript.arabic),
      ),
      child: child,
    );
  }
}

/// The app's shell: every tab stays mounted in one IndexedStack.
class ExampleShell extends StatefulWidget {
  const ExampleShell({super.key, required this.repository});

  final InvoiceRepository repository;

  @override
  State<ExampleShell> createState() => _ExampleShellState();
}

class _ExampleShellState extends State<ExampleShell> {
  static const int _invoicesTab = 1;

  int _index = 0;

  /// The home screen asks the Invoices tab to open an invoice through this.
  final ValueNotifier<int?> _openInvoice = ValueNotifier<int?>(null);

  @override
  void dispose() {
    _openInvoice.dispose();
    super.dispose();
  }

  static const List<AppDestination> _destinations = [
    AppDestination(icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard_rounded, label: 'Home'),
    AppDestination(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'Invoices'),
    AppDestination(icon: Icons.settings_outlined, selectedIcon: Icons.settings_rounded, label: 'Settings'),
  ];

  @override
  Widget build(BuildContext context) {
    return AdaptiveShell(
      destinations: _destinations,
      selectedIndex: _index,
      onDestinationSelected: (index) => setState(() => _index = index),
      body: IndexedStack(
        index: _index,
        children: [
          DashboardScreen(
            repository: widget.repository,
            onSeeInvoices: () => setState(() => _index = _invoicesTab),
            onOpenInvoice: (invoice) {
              setState(() => _index = _invoicesTab);
              _openInvoice.value = invoice.id;
            },
          ),
          RecordsScreen(repository: widget.repository, openRequest: _openInvoice),
          SettingsScreen(repository: widget.repository),
        ],
      ),
    );
  }
}

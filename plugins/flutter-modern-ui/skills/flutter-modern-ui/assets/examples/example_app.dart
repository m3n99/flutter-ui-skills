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
//   Signature  ledger lines: the label at the start, the amount in tabular
//              figures at the end, ruled between (the home card, the
//              sign-in mark).
//   Color      ink blue-black as the seed (fidelity), one accent, status
//              tones for money states.
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
      title: 'Design system example',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(config: widget.config),
      darkTheme: AppTheme.dark(config: widget.config),
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: AppMessenger.key,
      home: ExampleShell(repository: _repository),
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
  int _index = 0;

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
          DashboardScreen(repository: widget.repository),
          RecordsScreen(repository: widget.repository),
          const SettingsScreen(),
        ],
      ),
    );
  }
}

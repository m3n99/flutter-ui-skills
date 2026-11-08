// Wires the design system into an app: themes (light, dark, per-platform
// density), the single message component, and an adaptive shell whose tabs
// keep their state (IndexedStack also pauses tickers in hidden tabs, which
// MiniBarChart relies on).
//
// Run it: `void main() => runApp(const ExampleApp());`

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';
import 'dashboard_screen.dart';
import 'records_screen.dart';
import 'sample_data.dart';

class ExampleApp extends StatefulWidget {
  const ExampleApp({super.key, this.config = AppTheme.config});

  final AppThemeConfig config;

  @override
  State<ExampleApp> createState() => _ExampleAppState();
}

class _ExampleAppState extends State<ExampleApp> {
  final InvoiceRepository _repository = InvoiceRepository();
  int _index = 0;

  static const List<AppDestination> _destinations = [
    AppDestination(icon: Icons.space_dashboard_outlined, selectedIcon: Icons.space_dashboard_rounded, label: 'Home'),
    AppDestination(icon: Icons.receipt_long_outlined, selectedIcon: Icons.receipt_long_rounded, label: 'Invoices'),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Design system example',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(config: widget.config),
      darkTheme: AppTheme.dark(config: widget.config),
      themeMode: ThemeMode.system,
      scaffoldMessengerKey: AppMessenger.key,
      home: AdaptiveShell(
        destinations: _destinations,
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        body: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(repository: _repository),
            RecordsScreen(repository: _repository),
          ],
        ),
      ),
    );
  }
}

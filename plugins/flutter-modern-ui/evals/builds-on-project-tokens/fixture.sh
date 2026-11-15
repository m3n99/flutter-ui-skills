#!/usr/bin/env bash
# Seeds the workspace with a small Flutter project that has its own design
# system and a DESIGN.md that answers the intake questions, so the case can
# grade the file Claude writes. Runs only with `claude plugin eval --scaffold`.
set -euo pipefail

mkdir -p lib/core/ui lib/features/orders lib/features/customers

cat > pubspec.yaml <<'YAML'
name: shopbook
description: A shopkeeper's customers, orders and what they owe.
environment:
  sdk: ^3.5.0
dependencies:
  flutter:
    sdk: flutter
flutter:
  uses-material-design: true
YAML

cat > DESIGN.md <<'MD'
# Shopbook design contract

## Brief
Subject: a shopkeeper's notebook of customers and what they owe. Audience: the owner, at the counter. Job: find a customer and see their balance. Feeling: plain, trustworthy, quick. Signature: balances set in a ledger column.

## Decisions
- Platforms: Android only. Languages: English only.
- Look: flat cards (`BrandCard`), one per record.
- Emoji: none.
- Motion: none. Material's own motion only.

## System (lib/core/ui)
- Spacing: `Gaps.s4`, `Gaps.s8`, `Gaps.s16`, `Gaps.s24`. No other values.
- Colors: `context.brand.textMuted`, `context.brand.surfaceSoft`, `context.brand.danger`; everything else from `Theme.of(context).colorScheme`.
- Text: `context.type.title`, `context.type.body`, `context.type.caption`.
- Widgets: `BrandCard`, `BrandButton.primary`, `BrandEmpty`.
- Messages: `showBrandMessage(context, text)`.
MD

cat > lib/core/ui/gaps.dart <<'DART'
abstract final class Gaps {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s16 = 16;
  static const double s24 = 24;
}
DART

cat > lib/core/ui/brand.dart <<'DART'
import 'package:flutter/material.dart';

@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({required this.textMuted, required this.surfaceSoft, required this.danger});

  final Color textMuted;
  final Color surfaceSoft;
  final Color danger;

  @override
  BrandColors copyWith({Color? textMuted, Color? surfaceSoft, Color? danger}) => BrandColors(
        textMuted: textMuted ?? this.textMuted,
        surfaceSoft: surfaceSoft ?? this.surfaceSoft,
        danger: danger ?? this.danger,
      );

  @override
  BrandColors lerp(BrandColors? other, double t) => other == null || t < 0.5 ? this : other;
}

class BrandType {
  const BrandType(this._theme);
  final TextTheme _theme;
  TextStyle? get title => _theme.titleMedium;
  TextStyle? get body => _theme.bodyMedium;
  TextStyle? get caption => _theme.bodySmall;
}

extension BrandContext on BuildContext {
  BrandColors get brand => Theme.of(this).extension<BrandColors>()!;
  BrandType get type => BrandType(Theme.of(this).textTheme);
}
DART

cat > lib/core/ui/widgets.dart <<'DART'
import 'package:flutter/material.dart';

import 'brand.dart';
import 'gaps.dart';

class BrandCard extends StatelessWidget {
  const BrandCard({super.key, required this.child, this.onTap});
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: context.brand.surfaceSoft,
        borderRadius: BorderRadius.circular(Gaps.s16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(onTap: onTap, child: Padding(padding: const EdgeInsets.all(Gaps.s16), child: child)),
      );
}

class BrandButton extends StatelessWidget {
  const BrandButton.primary({super.key, required this.label, required this.onPressed});
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => FilledButton(onPressed: onPressed, child: Text(label));
}

class BrandEmpty extends StatelessWidget {
  const BrandEmpty({super.key, required this.title, required this.message, this.actionLabel, this.onAction});
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: context.type.title),
            const SizedBox(height: Gaps.s8),
            Text(message, style: context.type.body?.copyWith(color: context.brand.textMuted)),
            if (actionLabel != null) ...[
              const SizedBox(height: Gaps.s16),
              BrandButton.primary(label: actionLabel!, onPressed: onAction),
            ],
          ],
        ),
      );
}

void showBrandMessage(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
DART

cat > lib/features/customers/customer.dart <<'DART'
class Customer {
  const Customer({required this.id, required this.name, required this.phone, required this.balanceCents});
  final int id;
  final String name;
  final String phone;

  /// What the customer owes, in cents. Zero when settled.
  final int balanceCents;
}

abstract class CustomersRepository {
  Future<List<Customer>> load();
}
DART

cat > lib/features/orders/orders_screen.dart <<'DART'
import 'package:flutter/material.dart';

import '../../core/ui/brand.dart';
import '../../core/ui/gaps.dart';
import '../../core/ui/widgets.dart';

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      body: ListView(
        padding: EdgeInsets.fromLTRB(Gaps.s16, Gaps.s16, Gaps.s16, MediaQuery.paddingOf(context).bottom + Gaps.s24),
        children: [
          BrandCard(
            child: Row(
              children: [
                Expanded(child: Text('Order 1042', style: context.type.title, maxLines: 1, overflow: TextOverflow.ellipsis)),
                const SizedBox(width: Gaps.s8),
                Text('Nov 10', style: context.type.caption?.copyWith(color: context.brand.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
DART

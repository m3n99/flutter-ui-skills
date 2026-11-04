// Reference composition for the "Soft Minimal" direction.
// Shows: greeting header, hero summary card, quick actions, filter chips,
// grouped list with status pills, skeleton + empty + error states,
// bottom-inset handling, RTL-safe paddings, tabular figures.
//
// Presentation only: plug in the project's own state management where the
// `_DashboardState` placeholder is used.

import 'package:flutter/material.dart';

import '../design_system/design_system.dart';

enum DashboardStatus { loading, error, ready }

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, this.status = DashboardStatus.ready});

  // Replace with the project's state (Bloc state, controller value, etc.).
  final DashboardStatus status;

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: AppDurations.medium,
          switchInCurve: AppCurves.standard,
          child: switch (status) {
            DashboardStatus.loading => const _DashboardSkeleton(key: ValueKey('loading')),
            DashboardStatus.error => EmptyState.error(key: const ValueKey('error'), onRetry: () {}),
            DashboardStatus.ready => CustomScrollView(
                key: const ValueKey('ready'),
                slivers: [
                  const SliverToBoxAdapter(child: _GreetingHeader()),
                  SliverPadding(
                    padding: AppSpace.screenH,
                    sliver: SliverList.list(
                      children: [
                        const SizedBox(height: AppSpace.md),
                        const _BalanceCard(),
                        const SizedBox(height: AppSpace.lg),
                        const _QuickActions(),
                        const SizedBox(height: AppSpace.lg),
                        SectionHeader(title: 'Upcoming bills', actionLabel: 'See all', onAction: () {}),
                        const SizedBox(height: AppSpace.sm),
                        const _BillsGroup(),
                        SizedBox(height: bottomInset + AppSpace.lg),
                      ],
                    ),
                  ),
                ],
              ),
          },
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: 0,
        onDestinationSelected: (_) {},
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home_rounded), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.pie_chart_outline_rounded), selectedIcon: Icon(Icons.pie_chart_rounded), label: 'Insights'),
          NavigationDestination(icon: Icon(Icons.credit_card_outlined), selectedIcon: Icon(Icons.credit_card_rounded), label: 'Cards'),
          NavigationDestination(icon: Icon(Icons.person_outline_rounded), selectedIcon: Icon(Icons.person_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(AppSpace.screen, AppSpace.md, AppSpace.xs, 0),
      child: Row(
        spacing: AppSpace.sm,
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: colors.primaryContainer,
            child: Text('MK', style: text.titleSmall?.copyWith(color: colors.onPrimaryContainer)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning', style: text.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
                Text('Maya Haddad', style: text.titleLarge, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notifications',
            onPressed: () {},
            icon: const Badge(smallSize: 8, child: Icon(Icons.notifications_none_rounded)),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final text = context.textStyles;
    final on = colors.onPrimaryContainer;

    return AppCard(
      color: colors.primaryContainer,
      showBorder: false,
      borderRadius: AppRadius.xlAll,
      padding: const EdgeInsets.all(AppSpace.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Total balance', style: text.labelLarge?.copyWith(color: on.withValues(alpha: 0.8))),
              ),
              const StatusPill(label: '+4.2%', tone: StatusTone.success, icon: Icons.trending_up_rounded),
            ],
          ),
          const SizedBox(height: AppSpace.xs),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 12480.50),
            duration: context.reduceMotion ? Duration.zero : AppDurations.slow * 2,
            curve: AppCurves.standard,
            builder: (context, value, _) => Text(
              '\$${value.toStringAsFixed(2)}',
              style: text.displayMedium?.copyWith(
                color: on,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          Text(
            'Spent \$1,240 of \$2,000 this month',
            style: text.bodyMedium?.copyWith(color: on.withValues(alpha: 0.8)),
          ),
          const SizedBox(height: AppSpace.xs),
          ClipRRect(
            borderRadius: AppRadius.pillAll,
            child: LinearProgressIndicator(
              value: 0.62,
              minHeight: 8,
              color: colors.primary,
              backgroundColor: on.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    const actions = [
      (Icons.arrow_upward_rounded, 'Send'),
      (Icons.arrow_downward_rounded, 'Request'),
      (Icons.add_rounded, 'Top up'),
      (Icons.more_horiz_rounded, 'More'),
    ];

    return Row(
      children: [
        for (final (icon, label) in actions)
          Expanded(
            child: Pressable(
              onTap: () {},
              semanticLabel: label,
              child: Column(
                spacing: AppSpace.xs,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: context.colors.surfaceContainerHigh,
                      borderRadius: AppRadius.lgAll,
                    ),
                    child: Icon(icon, color: context.colors.onSurface),
                  ),
                  Text(label, style: context.textStyles.labelMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _BillsGroup extends StatelessWidget {
  const _BillsGroup();

  @override
  Widget build(BuildContext context) {
    final bills = [
      (Icons.bolt_rounded, 'Electricity', 'Due in 3 days', '\$84.20', StatusTone.warning, 'Due soon'),
      (Icons.wifi_rounded, 'Fiber internet', 'Auto-pay on Nov 12', '\$39.00', StatusTone.info, 'Scheduled'),
      (Icons.home_work_rounded, 'Rent', 'Paid Nov 1', '\$950.00', StatusTone.success, 'Paid'),
    ];

    if (bills.isEmpty) {
      return EmptyState(
        icon: Icons.receipt_long_rounded,
        title: 'No upcoming bills',
        message: 'Bills you add will appear here with their due dates.',
        actionLabel: 'Add a bill',
        onAction: () {},
      );
    }

    return AppCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (final (i, b) in bills.indexed) ...[
            if (i > 0) const Divider(indent: 72),
            ListTile(
              onTap: () {},
              leading: IconBadge(icon: b.$1),
              title: Text(b.$2, maxLines: 1, overflow: TextOverflow.ellipsis),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: AppSpace.xxs),
                child: Row(
                  spacing: AppSpace.xs,
                  children: [
                    StatusPill(label: b.$6, tone: b.$5),
                    Flexible(child: Text(b.$3, maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ],
                ),
              ),
              trailing: Text(
                b.$4,
                style: context.textStyles.titleMedium?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Padding(
        padding: EdgeInsets.all(AppSpace.screen),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.lg,
          children: [
            Row(
              spacing: AppSpace.sm,
              children: [
                SkeletonBox.circle(size: 44),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: AppSpace.xs,
                  children: [SkeletonBox(width: 90, height: 12), SkeletonBox(width: 140, height: 18)],
                ),
              ],
            ),
            SkeletonBox(height: 180, borderRadius: AppRadius.xlAll),
            SkeletonBox(height: 84, borderRadius: AppRadius.lgAll),
            SkeletonBox(width: 160, height: 18),
            SkeletonBox(height: 220, borderRadius: AppRadius.lgAll),
          ],
        ),
      ),
    );
  }
}

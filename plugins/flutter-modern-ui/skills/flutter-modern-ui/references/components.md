# Component patterns

Ready widgets live in `assets/design_system/widgets/`. The snippets below assume `context_ext.dart` (`context.colors`, `context.textStyles`, `context.palette`) and `tokens.dart` are imported.

## App bars
- Top-level tabs: large collapsing title.
```dart
SliverAppBar.large(
  title: const Text('Wallet'),
  actions: [IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded))],
)
```
- Detail screens: `SliverAppBar.medium` or a plain `AppBar` with `titleLarge`.
- Custom greeting header instead of an app bar is fine on home screens: avatar (40) + two-line text (bodyMedium muted "Good morning", titleLarge name) + trailing icon button, padded 20.
- Max 2 action icons. Overflow goes into a `MenuAnchor`.

## Cards
Use `AppCard` (elevation 0, tonal fill, hairline border, 16 radius, press-scale when tappable).
```dart
AppCard(
  onTap: () {},
  child: Row(
    spacing: AppSpace.sm,
    children: [
      IconBadge(icon: Icons.bolt_rounded),           // 44px tinted circle
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: AppSpace.xxs,
          children: [
            Text('Electricity', style: context.textStyles.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text('Due in 3 days', style: context.textStyles.bodySmall?.copyWith(color: context.colors.onSurfaceVariant)),
          ],
        ),
      ),
      Text('\$84.20', style: context.textStyles.titleMedium?.copyWith(fontFeatures: const [FontFeature.tabularFigures()])),
    ],
  ),
)
```
Hero/summary card: `primaryContainer` fill (or primary→tertiary gradient for Bold), `onPrimaryContainer` text, display-size number, 24 radius, 20–24 padding.

## Icon badge (tinted circle)
The quickest way to make list rows look designed.
```dart
class IconBadge extends StatelessWidget {
  const IconBadge({super.key, required this.icon, this.color, this.size = 44});
  final IconData icon;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = color ?? context.colors.primary;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: c.withValues(alpha: 0.12), shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.5, color: c),
    );
  }
}
```
(Included in `widgets/status_pill.dart`.)

## Lists
- Grouped list: one `AppCard(padding: EdgeInsets.zero)` containing `ListTile`s separated by `Divider(height: 1, indent: 72)`.
- `ListTile` with `leading: IconBadge`, `title` titleMedium, `subtitle` muted bodySmall, `trailing` chevron (`Icons.chevron_right_rounded`, `onSurfaceVariant`) or value text.
- Swipe actions: `Dismissible` with a rounded `errorContainer` background and an icon, confirm destructive actions.
- Section headers: `SectionHeader(title: 'Recent', actionLabel: 'See all', onAction: ...)`.

## Buttons
| Role | Widget | Notes |
|---|---|---|
| Primary (one per screen) | `FilledButton` | full width in forms/sheets: `SizedBox(width: double.infinity, child: FilledButton(...))` |
| Secondary | `FilledButton.tonal` or `OutlinedButton` | |
| Tertiary / inline | `TextButton` | |
| Destructive | `FilledButton` with `style: FilledButton.styleFrom(backgroundColor: colors.error, foregroundColor: colors.onError)` | confirm first |
| Icon-only | `IconButton` / `IconButton.filledTonal` | tooltip required |

- Buttons with icons: `FilledButton.icon(icon: Icon(...), label: Text(...))`.
- Loading state: keep size stable, swap label for an 20px `CircularProgressIndicator(strokeWidth: 2)` and disable.
- Avoid `ElevatedButton` (shadowed, dated look) unless the project already standardized on it.

## Sticky bottom CTA
```dart
bottomNavigationBar: SafeArea(
  minimum: const EdgeInsets.fromLTRB(AppSpace.screen, AppSpace.sm, AppSpace.screen, AppSpace.md),
  child: FilledButton(onPressed: _submit, child: const Text('Continue')),
),
```
Add a top hairline `Border(top: BorderSide(color: colors.outlineVariant))` or `softShadow` only when content scrolls under it.

## Inputs and forms
- Label above the field (titleSmall), field below, helper/error text under it. Floating labels look dated in most modern designs.
```dart
Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  spacing: AppSpace.xs,
  children: [
    Text('Email', style: context.textStyles.titleSmall),
    TextFormField(
      keyboardType: TextInputType.emailAddress,
      textInputAction: TextInputAction.next,
      autofillHints: const [AutofillHints.email],
      decoration: const InputDecoration(hintText: 'you@example.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
    ),
  ],
)
```
- Form field gap 16; group gap 24. Primary CTA pinned at the bottom.
- Always set `keyboardType`, `textInputAction`, `autofillHints`, and `obscureText` + visibility toggle for passwords.
- Validation: inline, after first submit or on blur, not on every keystroke from the first character.
- Choices: `SegmentedButton` for 2–4 exclusive options, `ChoiceChip`/`FilterChip` wrap for more, `Switch` for on/off settings, `showModalBottomSheet` picker for long lists. Avoid `DropdownButton` for primary flows; `DropdownMenu` is acceptable.

## Bottom sheets
```dart
showModalBottomSheet(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  builder: (context) => Padding(
    padding: EdgeInsets.fromLTRB(AppSpace.screen, 0, AppSpace.screen, MediaQuery.viewInsetsOf(context).bottom + AppSpace.lg),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: AppSpace.md,
      children: [
        Text('Add expense', style: context.textStyles.headlineSmall),
        // fields...
        SizedBox(width: double.infinity, child: FilledButton(onPressed: () {}, child: const Text('Save'))),
      ],
    ),
  ),
);
```
Prefer sheets over dialogs for anything with input or more than two actions. Dialogs are for short confirmations.

## Navigation
- `NavigationBar` with 3–5 destinations, outlined icon + filled `selectedIcon`, short one-word labels.
- Preserve tab state with `IndexedStack` or the router's shell (`StatefulShellRoute` in go_router) — whichever the project uses.
- Tabs inside a screen: `TabBar` with `TabBarThemeData(indicatorSize: TabBarIndicatorSize.label, dividerColor: Colors.transparent)`, or a `SegmentedButton` for 2–3 views.

## Chips, badges, status
- Status → `StatusPill(label: 'Paid', tone: StatusTone.success)` using `AppPalette` containers. Never raw red/green.
- Filters → horizontal `ListView` of `FilterChip`s under the header, padded 20, gap 8.
- Counters on icons → `Badge(label: Text('3'), child: Icon(...))`.

## Avatars and images
- `CircleAvatar` with `backgroundColor: colors.primaryContainer` + initials in `onPrimaryContainer` as fallback.
- Network images: fixed aspect (`AspectRatio`), rounded with `ClipRRect`, placeholder = `SkeletonBox`, fade in (`FadeInImage` or `frameBuilder` + `AnimatedOpacity`), error = icon on `surfaceContainerHigh`. Use `cached_network_image` if the project has it.

## Stats / KPI tiles
Label (labelMedium, muted) on top, value (headlineMedium or displaySmall, tabular figures) below, delta as `StatusPill` or small colored text with an arrow icon. Two per row on phones, four on tablets.

## Dialogs and feedback
- Confirmation dialog: `AlertDialog.adaptive`, title states the action ("Delete invoice?"), body explains the consequence in one sentence, actions `TextButton('Cancel')` + destructive `FilledButton`.
- Snackbars: floating, short, with an undo action for destructive operations. If the project has its own toast helper, use that instead.

# Layout, spacing and hierarchy

## Screen anatomy
Most modern mobile screens follow the same skeleton. Start from it, then remove what you don't need.

```
Scaffold (bg: surface)
└─ CustomScrollView
   ├─ SliverAppBar.large / .medium   ← big title that collapses on scroll
   ├─ SliverPadding(horizontal: 20)
   │   └─ SliverList / SliverToBoxAdapter
   │       ├─ Hero block (summary card, balance, greeting)      gap 24
   │       ├─ Quick actions / filter chips                      gap 24
   │       ├─ SectionHeader("Recent")                           gap 12
   │       └─ Cards or grouped list                             gap 12 between items
   └─ SliverToBoxAdapter(height: bottom inset + 24)
bottomNavigationBar: NavigationBar        (or)   bottom CTA bar inside SafeArea
```

- Prefer `CustomScrollView` + slivers for anything longer than one viewport. It gives collapsing headers, sticky headers and efficient lists in one scroll.
- Short static screens (settings detail, forms) can use `ListView(padding: ...)`.
- Never put a `ListView` inside a `Column` without `Expanded`, and never use `shrinkWrap: true` on long lists. Use slivers.

## Spacing rhythm
- Horizontal screen padding: `AppSpace.screen` (20). Full-bleed elements (carousels, images) break out deliberately and their inner content re-aligns to 20.
- Section gap 24, item gap 12, text-group gap 4–8.
- Inside a card: padding 16; title → subtitle 4; text block → actions 16.
- Align everything to the same left edge (start edge in RTL). Misaligned icons and text by 2–4 px read as "cheap" immediately.
- Bottom of scrollable content: add `MediaQuery.paddingOf(context).bottom + AppSpace.lg` so the last item clears the home indicator / nav bar.

## Hierarchy
Each screen answers "what's the one thing here?" in this order:
1. **Primary info** — largest text (headline/display), highest contrast.
2. **Primary action** — one `FilledButton` or FAB.
3. **Secondary info** — titleMedium/bodyMedium, `onSurfaceVariant`.
4. **Tertiary** — bodySmall/labelSmall, timestamps, metadata.

Tools for hierarchy (use several together): size, weight, color role, position (top-start wins), whitespace around the element, container color. Avoid using *only* bold or *only* size.

Group related items in one card or a grouped list (iOS-style inset section) instead of many tiny cards. Fewer, larger containers look calmer.

## Grids and lists
- Two-column grids: `SliverGrid` with `SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, childAspectRatio: ...)`. Choose aspect ratio from the content, then verify at text scale 1.3; prefer `mainAxisExtent` for fixed-height tiles.
- Horizontal carousels: `SizedBox(height: X)` + `ListView.separated(scrollDirection: Axis.horizontal, padding: EdgeInsets.symmetric(horizontal: 20), separatorBuilder: 12)`. Show a partial next item (~15%) so users know it scrolls.
- Lists of homogeneous rows: grouped inside one `AppCard` with `Divider(indent: 56)` between rows (indent aligns with text, not icon), or separated cards with 12 gaps. Pick one style per app.

## Responsive and adaptive
- Breakpoints (by width): compact < 600, medium 600–839, expanded ≥ 840. Read with `MediaQuery.sizeOf(context).width` (not `MediaQuery.of`, to avoid extra rebuilds).
- Tablets/foldables: cap content width (`ConstrainedBox(maxWidth: 640)` centered) for forms and reading; use 2–3 column grids for collections; switch `NavigationBar` → `NavigationRail` at ≥ 600.
- Landscape phones: avoid fixed heights for hero blocks; use `AspectRatio` or `LayoutBuilder`.
- Platform adaptivity where it matters: `Switch.adaptive`, `CircularProgressIndicator.adaptive`, Cupertino-style back swipe (default on iOS), `showAdaptiveDialog`. Keep the brand look otherwise identical.

## Text resilience
- Every dynamic `Text` in a row: wrap in `Expanded`/`Flexible`, set `maxLines` and `overflow: TextOverflow.ellipsis`.
- Test at `MediaQuery.textScalerOf` 1.0 and 1.3. Never clamp text scaling globally below 1.3; if a layout breaks, fix the layout (wrap, allow growth), don't block scaling.
- Avoid fixed heights on containers holding text. Use padding and min constraints.

## RTL and localization
- Use `EdgeInsetsDirectional`, `AlignmentDirectional`, `PositionedDirectional`, `BorderRadiusDirectional`, `TextAlign.start/end`.
- Directional icons (arrows, chevrons, back, send) must mirror: use icons that auto-mirror (`Icons.arrow_back` does via `matchTextDirection`) or wrap with `Directionality`-aware logic. Non-directional icons (search, settings) must not mirror.
- Numbers, phone numbers and code stay LTR inside RTL text: wrap with `Directionality(textDirection: TextDirection.ltr, ...)` or Unicode isolates.
- German/Arabic strings run 30–40% longer than English: leave room, never truncate primary labels.

## Keyboard and safe areas
- Forms: `Scaffold(resizeToAvoidBottomInset: true)` + scrollable body; pin the primary CTA above the keyboard with `Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom))` in the bottom bar.
- Dismiss keyboard on tap outside (`GestureDetector(onTap: () => FocusScope.of(context).unfocus())`) and on scroll (`keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag`).
- Wrap screen content (not the background) in `SafeArea`; full-bleed headers extend under the status bar and pad their content by `MediaQuery.paddingOf(context).top`.

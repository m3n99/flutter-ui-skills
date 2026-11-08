# Platforms: desktop, tablet and touch

One codebase often ships to Android and Windows (or iOS and macOS). Touch and pointer need different metrics and affordances. Decide from `Theme.of(context).platform` / `context.density`, not `Platform.isX` (which breaks on web and in tests).

## Density

`AppDensity` (ThemeExtension) is chosen from the platform in `AppTheme.build`:

| | Touch | Desktop |
|---|---|---|
| Buttons, inputs | 48 px | 40 px |
| List / table rows | 56 px | 40 px |
| Tap targets | padded to 48 × 48 | shrink-wrapped |
| Visual density | standard | compact |
| Screen padding | direction default (16–24) | same |

Check touch targets in tests with `androidTapTargetGuideline` (the sheet test does). If the desktop build may run on touch screens, set `desktopDensity.control` to 48.

## Pointer affordances (desktop and web on desktop)

- **Hover**: every interactive surface shows a hover state. Material ink widgets do; custom ones use `InkWell` (or `MouseRegion` + an overlay of `onSurface` at 0.08). `AppCard` darkens its border on hover; raised tiles lift their shadow.
- **Cursor**: `SystemMouseCursors.click` on anything clickable (ink widgets set it; read-only fields that open pickers set `mouseCursor`).
- **Focus**: visible focus for keyboard users (ink focus highlight, or a 2 px `primary` outline); logical traversal order (`FocusTraversalGroup`, `FocusTraversalOrder`).
- **Scrollbars**: always visible on desktop (`ScrollbarThemeData.thumbVisibility`, set by the template on pointer platforms).
- **Tooltips**: on every icon-only button, after a 500 ms hover wait (template).
- **Context menus**: right-click on rows → `MenuAnchor` at the pointer position (`GestureDetector(onSecondaryTapDown: …)`), mirroring the row's actions (Open, Edit, Delete).
- **Text selection**: wrap read-only data views in `SelectionArea` so users can copy values.
- **Dialogs over sheets**: from 600 px, sheets become centered dialogs (`showAppSheet`).
- **Messages**: floating, 420 px wide, bottom (template). `fluttertoast` has no Windows support; use the SnackBar-based `AppMessenger` through a global `ScaffoldMessengerKey`.

## Keyboard shortcuts

Common desktop expectations, wired with `Shortcuts` + `Actions` (or `CallbackShortcuts` for simple screens):

| Shortcut | Action |
|---|---|
| Ctrl/⌘ + N | New record |
| Ctrl/⌘ + F | Focus search |
| Ctrl/⌘ + S | Save the open form |
| Esc | Close sheet / dialog / clear search |
| Enter | Submit the focused form / open the selected row |
| Delete | Delete the selected row (with confirmation or Undo) |
| ↑ / ↓ | Move selection in lists and tables |

```dart
CallbackShortcuts(
  bindings: {
    const SingleActivator(LogicalKeyboardKey.keyN, control: true): _openForm,
    const SingleActivator(LogicalKeyboardKey.keyF, control: true): _searchFocus.requestFocus,
  },
  child: Focus(autofocus: true, child: screen),
)
```

Show shortcuts in tooltips ("New invoice (Ctrl+N)") and in menus (`MenuItemButton(shortcut: …)`).

## Window

- Title, minimum size and remembered bounds: the `window_manager` package (`setMinimumSize(const Size(1000, 640))`, `setTitle`, save/restore bounds). Ask before adding the dependency.
- Test at 1366 × 768 and 1920 × 1080, plus the minimum size.
- Content caps at 1440 px and centers; tables may use the full width up to the cap.

## Navigation by width

| Width | Pattern |
|---|---|
| < 600 | `NavigationBar` (3–5 destinations), FAB bottom-end |
| 600–1199 | `NavigationRail` with labels below icons, FAB at the top of the rail |
| ≥ 1200 | extended `NavigationRail` (labels beside icons) or a permanent drawer for many sections |

`AdaptiveShell` implements this. Keep each tab's state alive (`IndexedStack`, or the router's stateful shell); `IndexedStack` also pauses tickers in hidden tabs.

## Master-detail and tables

From expanded width, show list + detail side by side; from large width, data-heavy screens can switch the list to a table (`data-display.md` › Tables). Phones keep cards: a table row truncates `dd/MM/yyyy` and amounts at 360 px.

## Tablets and foldables

- Treat medium/expanded like small desktop layouts but keep touch metrics (density follows the platform, layout follows the width).
- Landscape phones: no fixed-height hero blocks; use `AspectRatio` or `LayoutBuilder`.
- Foldables: avoid placing interactive elements across the hinge (`MediaQuery.displayFeaturesOf`).

## Platform-specific polish

- iOS: Cupertino back swipe (default), `Switch.adaptive`, `CircularProgressIndicator.adaptive`, `showAdaptiveDialog`, `RefreshIndicator.adaptive`. Keep the brand look otherwise identical.
- Android: predictive back (template's page transitions; enable `android:enableOnBackInvokedCallback="true"` in the manifest).
- Haptics on touch only (`HapticFeedback.selectionClick` for toggles, `lightImpact` for success), never on desktop.

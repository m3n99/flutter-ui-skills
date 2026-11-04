# Anti-patterns → fixes

Things that make Flutter UI look default, dated or machine-generated. Scan every diff for these.

| # | Anti-pattern | Why it looks bad | Fix |
|---|---|---|---|
| 1 | `Colors.blue`, `Colors.grey[200]`, `Color(0xFF...)` in widgets | off-brand, breaks dark mode | `ColorScheme` roles / `AppPalette` |
| 2 | `fontSize: 15`, `fontSize: 22` scattered | no type system, inconsistent hierarchy | `textTheme` roles |
| 3 | `SizedBox(height: 10)`, `padding: EdgeInsets.all(15)` | off-grid, uneven rhythm | `AppSpace` tokens, `Column(spacing:)` |
| 4 | Same spacing between everything | no grouping, flat page | small gaps inside groups, large between |
| 5 | `Card(elevation: 4)` / heavy `BoxShadow(blurRadius: 4, color: Colors.black26)` | 2015 Material look, muddy in dark | elevation 0 + tonal fill + hairline border; soft shadow only for floating UI |
| 6 | Purple M3 default seed / unchanged `ThemeData()` | instantly recognizable as "unstyled" | seed from brand + chosen direction |
| 7 | M3 surface tint on app bar/cards/sheets | grayish-purple wash | `surfaceTintColor: Colors.transparent` |
| 8 | Centered `CircularProgressIndicator` for content loads | blank, jumpy | skeletons shaped like content |
| 9 | Missing empty and error states | broken-looking when data is absent | `EmptyState` / error with retry |
| 10 | Raw `ElevatedButton` everywhere, several primary buttons | no action hierarchy | one `FilledButton`, others tonal/outlined/text |
| 11 | Buttons 36–40 px tall, tiny tap areas | feels cramped, hard to tap | 48–52 min height, 48×48 targets |
| 12 | Floating labels + underline inputs | dated | filled inputs, label above, focus border |
| 13 | Mixed icon styles (filled + outlined + sharp) | visual noise | one family; filled only for selected |
| 14 | Text overflow stripes / unbounded `Row` text | broken at runtime | `Expanded` + `maxLines` + ellipsis |
| 15 | `EdgeInsets.only(left:)`, `Alignment.centerLeft` | breaks RTL | directional variants |
| 16 | Dividers between every element | cluttered | whitespace and grouping; dividers only inside grouped lists |
| 17 | Gradients on everything, random accent colors | noisy, cheap | one accent; gradients only on a single hero element |
| 18 | Pure black/white backgrounds | harsh | `surface` roles from the seed |
| 19 | `AppBar` with centered title + elevation + colored background by default | old Android look | surface-colored, start-aligned, large collapsing title where appropriate |
| 20 | Every item in its own card with shadow | busy, heavy | group into one card or a plain list |
| 21 | Long animations, bouncy curves, no reduced-motion support | sluggish | 150–400 ms, ease-out, respect `disableAnimations` |
| 22 | Placeholder lorem/"Item 1" data in examples | can't judge the design | realistic content lengths and values |
| 23 | Emoji as icons in production UI | inconsistent rendering | icon family |
| 24 | `shrinkWrap: true` long lists inside `Column`/`SingleChildScrollView` | jank, no laziness | slivers |
| 25 | `MediaQuery.of(context).size` everywhere | unnecessary rebuilds | `MediaQuery.sizeOf(context)` |
| 26 | Hard-coded strings and hard-coded `TextDirection.ltr` | breaks i18n | project's l10n system |
| 27 | New colors/styles invented per screen | drift | add to the theme/tokens once, reuse |

## Smell test
If a screenshot of the screen could be any app, it's not done. Look for at least one **signature element** from the chosen direction: a large expressive header, a hero card, a distinctive radius/shape language, tinted icon badges, or confident typography.

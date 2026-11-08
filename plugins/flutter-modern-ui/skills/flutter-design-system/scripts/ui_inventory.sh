#!/usr/bin/env bash
# UI inventory of a Flutter project: design-system files, hard-coded values,
# RTL risks, component and motion usage. Read-only.
#
# Usage (from the project root):
#   bash ui_inventory.sh [dir ...]        default: lib
#   bash ui_inventory.sh apps/app/lib packages/ui/lib

set -uo pipefail

dirs=("$@")
[ ${#dirs[@]} -eq 0 ] && dirs=(lib)
for d in "${dirs[@]}"; do
  [ -d "$d" ] || { echo "No such directory: $d" >&2; exit 1; }
done

EXCLUDES=(--include='*.dart' --exclude='*.g.dart' --exclude='*.freezed.dart' --exclude='*.gr.dart'
  --exclude-dir='.dart_tool' --exclude-dir='build' --exclude-dir='generated' --exclude-dir='l10n')
THEME_DIRS='(^|/)(theme|themes|design_system|design-system|ui_kit|styles)/'

lines()   { grep -rnE "${EXCLUDES[@]}" "$1" "${dirs[@]}" 2>/dev/null; }
files()   { grep -rlE "${EXCLUDES[@]}" "$1" "${dirs[@]}" 2>/dev/null | sort -u; }
matches() { grep -rhoE "${EXCLUDES[@]}" "$1" "${dirs[@]}" 2>/dev/null; }
count()   { lines "$1" | wc -l | tr -d ' '; }
numbers() { grep -oE '[0-9]+(\.[0-9]+)?' | sort -n | uniq -c | sort -rn | head -n "${1:-20}"; }
section() { printf '\n## %s\n' "$1"; }

echo "# UI inventory: ${dirs[*]}"

section "Platforms (folders at the project root)"
for p in android ios windows macos linux web; do [ -d "$p" ] && printf '%s ' "$p"; done
echo

section "Localization"
arb=$(find . -name '*.arb' -not -path './build/*' -not -path './.dart_tool/*' 2>/dev/null | sort)
if [ -n "$arb" ]; then echo "$arb"; else echo "no ARB files"; fi
[ -f l10n.yaml ] && echo "l10n.yaml present (gen-l10n)"
grep -q "flutter_intl" pubspec.yaml 2>/dev/null && echo "flutter_intl / intl_utils configured (regenerate with: dart pub global run intl_utils:generate)"

section "Design-system files"
files 'ThemeData\(|ThemeExtension<|ColorScheme\.(fromSeed|light|dark)\(|TextTheme\(|class App(Colors|Spacing|Space|Radius|Theme|TextStyles|Typography|Palette|Dimens|Sizes)\b'

section "Fonts in pubspec.yaml"
grep -nE '^\s*-?\s*family:' pubspec.yaml 2>/dev/null || echo "no bundled fonts"

section "Hard-coded colors outside theme files"
colors=$(lines '(^|[^A-Za-z_])Colors\.[a-z][A-Za-z0-9]*|Color\(0x' | grep -vE "$THEME_DIRS" | grep -v 'Colors\.transparent')
echo "count: $(printf '%s' "$colors" | grep -c . )"
printf '%s\n' "$colors" | head -n 15

section "Font sizes in widgets (value: occurrences)"
matches 'fontSize:[[:space:]]*[0-9.]+' | numbers

section "Spacing values in EdgeInsets and SizedBox gaps (value: occurrences)"
{ matches 'EdgeInsets[A-Za-z]*\.[a-zA-Z]+\([^)]*\)'; matches 'SizedBox\((height|width):[[:space:]]*[0-9.]+'; matches 'spacing:[[:space:]]*[0-9.]+'; } | numbers 25

section "Radius values (value: occurrences)"
matches '(BorderRadius|Radius)\.circular\([0-9.]+\)' | numbers

section "Elevation and shadows"
echo "elevation values:"
matches 'elevation:[[:space:]]*[0-9.]+' | numbers 10
echo "BoxShadow: $(count 'BoxShadow\(')"

section "RTL risks (left/right instead of start/end)"
rtl=$(lines 'EdgeInsets\.only\([^)]*(left|right):|EdgeInsets\.fromLTRB|Alignment\.(centerLeft|centerRight|topLeft|topRight|bottomLeft|bottomRight)|TextAlign\.(left|right)|Positioned\([^)]*(left|right):')
echo "count: $(printf '%s' "$rtl" | grep -c . )"
printf '%s\n' "$rtl" | head -n 10

section "Components (occurrences)"
printf '%-34s %s\n' \
  "Card(" "$(count '[^A-Za-z]Card\(')" \
  "ElevatedButton" "$(count 'ElevatedButton')" \
  "FilledButton" "$(count 'FilledButton')" \
  "CircularProgressIndicator" "$(count 'CircularProgressIndicator')" \
  "Shimmer / skeleton" "$(count 'Shimmer|Skeleton')" \
  "SnackBar / showSnackBar" "$(count 'SnackBar\(|showSnackBar')" \
  "Toast (fluttertoast etc.)" "$(count 'Fluttertoast|showToast|Toast\(')" \
  "showModalBottomSheet" "$(count 'showModalBottomSheet')" \
  "showDialog" "$(count 'showDialog|showAdaptiveDialog')" \
  "DataTable" "$(count 'DataTable\(|PaginatedDataTable')" \
  "TextFormField / TextField" "$(count 'TextFormField\(|TextField\(')" \
  "shrinkWrap: true" "$(count 'shrinkWrap:[[:space:]]*true')" \
  "MediaQuery.of(context).size" "$(count 'MediaQuery\.of\(context\)\.size')"

section "Motion (occurrences)"
printf '%-34s %s\n' \
  "AnimationController" "$(count 'AnimationController\(')" \
  "Animated* widgets" "$(count 'Animated[A-Z][A-Za-z]+\(')" \
  "AnimatedList / SliverAnimatedList" "$(count 'AnimatedList\(|SliverAnimatedList\(')" \
  "Hero" "$(count 'Hero\(')" \
  "PageRouteBuilder / custom routes" "$(count 'PageRouteBuilder|CustomTransitionPage')" \
  "flutter_animate (.animate())" "$(count '\.animate\(\)')" \
  "Lottie / Rive" "$(count 'Lottie\.|RiveAnimation')" \
  "disableAnimations checks" "$(count 'disableAnimations')"

echo
echo "Next: write the found → token mapping (references/study-existing-app.md)."

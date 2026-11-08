#!/usr/bin/env bash
# Builds a throwaway Flutter app from the plugin's templates, the way a
# project would use them: design system in lib/design_system, examples in
# lib/examples, the verify harness in test/ui, and a bundled font.
# CI uses it to analyze, test and screenshot the templates; contributors can
# run it locally before opening a PR.
#
#   bash scripts/sandbox.sh [output-dir]       default: build/sandbox
#   cd build/sandbox && flutter analyze && flutter test test/ui

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/build/sandbox}"
SKILLS="$ROOT/plugins/flutter-modern-ui/skills"

rm -rf "$OUT"
flutter create --project-name app --org dev.flutteruiskills --platforms android,windows --no-pub "$OUT" >/dev/null
rm -rf "$OUT/lib" "$OUT/test"
mkdir -p "$OUT/lib" "$OUT/test/ui" "$OUT/assets/fonts"

cp -R "$SKILLS/flutter-modern-ui/assets/design_system" "$OUT/lib/design_system"
cp -R "$SKILLS/flutter-modern-ui/assets/examples" "$OUT/lib/examples"
cp "$SKILLS/flutter-ui-verify/assets/harness/"*.dart "$OUT/test/ui/"

cat > "$OUT/lib/main.dart" <<'DART'
import 'package:flutter/material.dart';

import 'examples/example_app.dart';

void main() => runApp(const ExampleApp());
DART

# A font with Latin and Arabic glyphs, so screenshots show real text in both directions.
FONT_BASE="https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexsansarabic"
for weight in Regular Medium SemiBold Bold; do
  curl -fsSL "$FONT_BASE/IBMPlexSansArabic-$weight.ttf" -o "$OUT/assets/fonts/IBMPlexSansArabic-$weight.ttf"
done
cat >> "$OUT/pubspec.yaml" <<'YAML'
  fonts:
    - family: IBM Plex Sans Arabic
      fonts:
        - asset: assets/fonts/IBMPlexSansArabic-Regular.ttf
        - asset: assets/fonts/IBMPlexSansArabic-Medium.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexSansArabic-SemiBold.ttf
          weight: 600
        - asset: assets/fonts/IBMPlexSansArabic-Bold.ttf
          weight: 700
YAML

# The DIRECTION step a project would do: set the bundled font in the theme config.
THEME="$OUT/lib/design_system/app_theme.dart"
sed -i.bak "s/static const AppThemeConfig config = AppThemeConfig();/static const AppThemeConfig config = AppThemeConfig(fontFamily: 'IBM Plex Sans Arabic');/" "$THEME"
rm -f "$THEME.bak"
grep -q "AppThemeConfig(fontFamily: 'IBM Plex Sans Arabic')" "$THEME" || { echo "Could not set the font in $THEME" >&2; exit 1; }

(cd "$OUT" && flutter pub get >/dev/null)
echo "Sandbox ready: $OUT"

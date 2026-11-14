#!/usr/bin/env bash
# Builds a throwaway Flutter app from the plugin's templates, the way a
# project would get them: the design system (both kits) and the harnesses
# through the plugin's copy scripts, the examples in lib/examples, and a
# bundled font. The repo's own tests (ci/) go to test/ci.
# CI uses it to analyze, test and screenshot the templates; contributors can
# run it locally before opening a PR.
#
#   bash scripts/sandbox.sh [--material-ui | --framework-material] [output-dir]
#   cd build/sandbox && flutter analyze && flutter test test/ui test/pdf test/ci
#
# --material-ui         the app depends on material_ui and cupertino_ui (what
#                       `flutter create` does from Flutter 3.50): the scripts
#                       rewrite every Material import
# --framework-material  the app still imports package:flutter/material.dart
# Default: whatever this Flutter's `flutter create` produces.

set -euo pipefail

MODE=default
case "${1:-}" in
  --material-ui) MODE=material_ui; shift ;;
  --framework-material) MODE=framework; shift ;;
esac

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${1:-$ROOT/build/sandbox}"
SKILLS="$ROOT/plugins/flutter-modern-ui/skills"

rm -rf "$OUT"
flutter create --project-name app --org dev.flutteruiskills --platforms android,windows --no-pub "$OUT" >/dev/null
rm -rf "$OUT/lib" "$OUT/test"
mkdir -p "$OUT/lib" "$OUT/test/ci" "$OUT/assets/fonts"
cd "$OUT"

has_dep() { grep -qE "^  $1:" pubspec.yaml; }
case "$MODE" in
  material_ui)
    has_dep material_ui || flutter pub add material_ui >/dev/null
    has_dep cupertino_ui || flutter pub add cupertino_ui >/dev/null
    ;;
  framework)
    if has_dep material_ui; then flutter pub remove material_ui >/dev/null; fi
    ;;
esac
# The printed-document example (lib/examples/invoice_pdf.dart) and its
# harness use the pdf package.
flutter pub add pdf >/dev/null
if has_dep material_ui && ! has_dep cupertino_ui; then flutter pub add cupertino_ui >/dev/null; fi

python3 "$SKILLS/flutter-modern-ui/scripts/copy_design_system.py" --kit all --to lib/design_system
cp -R "$SKILLS/flutter-modern-ui/assets/examples" lib/examples
cp "$ROOT/ci/"*.dart test/ci/
python3 "$SKILLS/flutter-modern-ui/scripts/copy_design_system.py" --adapt lib/examples test/ci
python3 "$SKILLS/flutter-ui-verify/scripts/copy_harness.py" --to test/ui --pdf test/pdf --design-system-test

cat > lib/main.dart <<'DART'
import 'package:flutter/widgets.dart';

import 'examples/example_app.dart';

void main() => runApp(const ExampleApp());
DART

# A font with Latin and Arabic glyphs, so screenshots show real text in both directions.
FONT_BASE="https://raw.githubusercontent.com/google/fonts/main/ofl/ibmplexsansarabic"
for weight in Regular Medium SemiBold Bold; do
  curl -fsSL "$FONT_BASE/IBMPlexSansArabic-$weight.ttf" -o "assets/fonts/IBMPlexSansArabic-$weight.ttf"
done
cat >> pubspec.yaml <<'YAML'
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

# The DIRECTION step a project would do, from the example app's brief
# (lib/examples/example_app.dart): an ink blue-black seed kept exact, and the
# bundled font.
THEME="lib/design_system/app_theme.dart"
CONFIG="AppThemeConfig(seed: Color(0xFF1F2A44), variant: DynamicSchemeVariant.fidelity, fontFamily: 'IBM Plex Sans Arabic')"
sed -i.bak "s/static const AppThemeConfig config = AppThemeConfig();/static const AppThemeConfig config = $CONFIG;/" "$THEME"
rm -f "$THEME.bak"
grep -qF "$CONFIG" "$THEME" || { echo "Could not set the theme config in $THEME" >&2; exit 1; }

flutter pub get >/dev/null
echo "Sandbox ready ($(has_dep material_ui && echo material_ui || echo 'package:flutter/material.dart')): $OUT"

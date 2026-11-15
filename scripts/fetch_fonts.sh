#!/usr/bin/env bash
# Downloads IBM Plex Sans Arabic (Latin and Arabic glyphs) for the sandbox app
# and the glyph check, from one pinned commit of google/fonts, so a change in
# that repo can't break or silently alter this repo's CI.
#
#   bash scripts/fetch_fonts.sh <output-dir> [weight ...]     # default: Regular Medium SemiBold Bold
#
# To move the pin: put the new commit of https://github.com/google/fonts in
# FONTS_COMMIT, run the sandbox, and look at the screenshots.

set -euo pipefail

FONTS_COMMIT="cc39c4c2c304bc368c9b7c311ea2bcc6013299fe"
BASE="https://raw.githubusercontent.com/google/fonts/$FONTS_COMMIT/ofl/ibmplexsansarabic"

OUT="${1:?usage: fetch_fonts.sh <output-dir> [weight ...]}"
shift
WEIGHTS=("$@")
if [ ${#WEIGHTS[@]} -eq 0 ]; then WEIGHTS=(Regular Medium SemiBold Bold); fi

mkdir -p "$OUT"
for weight in "${WEIGHTS[@]}"; do
  curl -fsSL --retry 3 "$BASE/IBMPlexSansArabic-$weight.ttf" -o "$OUT/IBMPlexSansArabic-$weight.ttf"
done

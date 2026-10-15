#!/usr/bin/env bash
# Subsets the source fonts in design/fonts-src/ to Latin and writes
# woff2 files to site/assets/fonts/. Variable axes are kept.
# Run from the repo root:  bash design/subset-fonts.sh
set -euo pipefail

PYFTSUBSET="design/.venv/bin/pyftsubset"
SRC="design/fonts-src"
OUT="site/assets/fonts"

# Latin (same ranges as Google Fonts' "latin" subset) + arrows ←↑→↓
UNICODES="U+0000-00FF,U+0131,U+0152-0153,U+02BB-02BC,U+02C6,U+02DA,U+02DC,\
U+0304,U+0308,U+0329,U+2000-206F,U+20AC,U+2122,U+2190-2193,U+2212,U+2215,\
U+FEFF,U+FFFD"

# Default features (kern, liga, calt, ...) plus tabular/lining figures
FEATURES="*default*,tnum,case,zero"

subset() {
  "$PYFTSUBSET" "$1" \
    --output-file="$2" \
    --flavor=woff2 \
    --unicodes="$UNICODES" \
    --layout-features="$FEATURES" \
    --name-IDs='*'
}

subset "$SRC/inter-var.original.woff2"   "$OUT/inter-var.woff2"
subset "$SRC/JetBrainsMono[wght].ttf"    "$OUT/jetbrains-mono-var.woff2"

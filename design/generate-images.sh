#!/usr/bin/env bash
# Generates the favicon set, logo and Open Graph image into site/assets/.
#   Icons:    rasterized from site/assets/icons/favicon.svg (the source mark).
#   OG image: design/og-image.html rendered in headless Firefox, so it uses
#             the site's real fonts and design tokens.
# Needs: ImageMagick 7 (with librsvg), Firefox, python3.
# Run from the repo root:  bash design/generate-images.sh
set -euo pipefail

SVG="site/assets/icons/favicon.svg"
ICONS="site/assets/icons"
IMG="site/assets/img"
PORT=8799

TMP="$(mktemp -d)"
trap 'kill "${SERVER_PID:-}" 2>/dev/null || true; rm -rf "$TMP"' EXIT

# PNG optimization: strip metadata, max zlib compression.
# Opaque icons have few colors, so a 256-color palette (PNG8) is visually identical.
optimize_png() {
  local file="$1" mode="${2:-rgb}"
  local format="PNG24"
  [[ "$mode" == "palette" ]] && format="PNG8"
  [[ "$mode" == "alpha" ]] && format="PNG32"
  magick "$file" -strip \
    -define png:compression-level=9 \
    -define png:compression-filter=5 \
    -define png:compression-strategy=1 \
    -define png:exclude-chunks=date,time \
    "$format:$file"
}

# Render the SVG at an exact pixel size by setting width/height on the root
# element (crisper than resizing a large raster down).
render_svg() {
  local src="$1" size="$2" out="$3"
  sed "s/<svg /<svg width=\"$size\" height=\"$size\" /" "$src" > "$TMP/render.svg"
  magick -background none "$TMP/render.svg" "$out"
}

echo "favicon.ico (32×32)"
render_svg "$SVG" 32 "$TMP/favicon-32.png"
magick "$TMP/favicon-32.png" "$ICONS/favicon.ico"

echo "apple-touch-icon.png (180×180)"
# iOS rounds the corners itself and fills transparency with black,
# so this one is a full-bleed square.
sed 's/rx="[^"]*"/rx="0"/' "$SVG" > "$TMP/square.svg"
render_svg "$TMP/square.svg" 180 "$ICONS/apple-touch-icon.png"
optimize_png "$ICONS/apple-touch-icon.png" palette

echo "logo-512.png (512×512)"
# Keeps full alpha: PNG8's on/off transparency would make the rounded corners jagged.
render_svg "$SVG" 512 "$ICONS/logo-512.png"
optimize_png "$ICONS/logo-512.png" alpha

echo "og-image.png (1200×630)"
python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER_PID=$!
sleep 1
mkdir -p "$TMP/profile"
firefox --headless --no-remote --profile "$TMP/profile" \
  --window-size=1200,630 \
  --screenshot "$TMP/og.png" \
  "http://127.0.0.1:$PORT/design/og-image.html" >/dev/null 2>&1
magick "$TMP/og.png" -crop 1200x630+0+0 +repage "$IMG/og-image.png"
optimize_png "$IMG/og-image.png"

echo "Done:"
ls -l "$ICONS/favicon.ico" "$ICONS/apple-touch-icon.png" "$ICONS/logo-512.png" "$IMG/og-image.png"

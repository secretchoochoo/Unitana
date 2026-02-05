#!/usr/bin/env bash
set -euo pipefail

# Fetch required Google Fonts TTFs and place them into app/unitana/assets/fonts/
# Needed for deterministic tests/goldens when GoogleFonts runtime fetching is disabled.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
APP_DIR="$ROOT_DIR/app/unitana"
FONTS_DIR="$APP_DIR/assets/fonts"

mkdir -p "$FONTS_DIR"

UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120 Safari/537.36"

fetch_family_zip() {
  local family="$1"
  local outzip="$2"
  local url="https://fonts.google.com/download?family=${family}"
  echo "Fetching ${family}..."

  # Some environments get HTML interstitials unless we look like a browser.
  curl -fLsS -L \
    --retry 3 --retry-delay 1 --retry-all-errors \
    -A "$UA" \
    -H "Referer: https://fonts.google.com/" \
    -H "Accept: text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8" \
    -o "$outzip" \
    "$url"

  # Validate the file is actually a zip before unzip tries.
  if ! unzip -tqq "$outzip" >/dev/null 2>&1; then
    echo ""
    echo "ERROR: Download for ${family} was not a valid zip."
    echo "This usually means fonts.google.com returned HTML (interstitial / consent / bot check)."
    echo ""
    echo "First 20 lines of the downloaded file:"
    echo "------------------------------------------------------------"
    head -n 20 "$outzip" || true
    echo "------------------------------------------------------------"
    echo ""
    echo "Try again on a different network, or use the GitHub fallback commands shown in the script output."
    exit 2
  fi
}

extract_ttf() {
  local zipfile="$1"
  local tmpdir="$2"
  rm -rf "$tmpdir"
  mkdir -p "$tmpdir"
  unzip -q "$zipfile" -d "$tmpdir"
  find "$tmpdir" -type f -name "*.ttf" -maxdepth 6 -print0 | while IFS= read -r -d '' f; do
    cp -f "$f" "$FONTS_DIR/$(basename "$f")"
  done
}

require_files=(
  "RobotoSlab-Bold.ttf"
  "RobotoSlab-SemiBold.ttf"
  "RobotoMono-Bold.ttf"
  "RobotoMono-SemiBold.ttf"
  "Inconsolata-ExtraBold.ttf"
)

TMP_BASE="$(mktemp -d)"
trap 'rm -rf "$TMP_BASE"' EXIT

Z1="$TMP_BASE/roboto_slab.zip"
Z2="$TMP_BASE/roboto_mono.zip"
Z3="$TMP_BASE/inconsolata.zip"

fetch_family_zip "Roboto%20Slab" "$Z1"
fetch_family_zip "Roboto%20Mono" "$Z2"
fetch_family_zip "Inconsolata" "$Z3"

extract_ttf "$Z1" "$TMP_BASE/roboto_slab"
extract_ttf "$Z2" "$TMP_BASE/roboto_mono"
extract_ttf "$Z3" "$TMP_BASE/inconsolata"

missing=0
for f in "${require_files[@]}"; do
  if [[ ! -f "$FONTS_DIR/$f" ]]; then
    echo "Missing required font: $f"
    missing=1
  fi
done

if [[ "$missing" -ne 0 ]]; then
  echo ""
  echo "Some required font files were not found after download."
  echo "If a weight file is not present in the family zip, we can map to the closest available weight."
  exit 2
fi

echo ""
echo "Fonts installed into: $FONTS_DIR"
echo "Next: cd $APP_DIR && flutter test --update-goldens ..."

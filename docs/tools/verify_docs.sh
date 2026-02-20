#!/usr/bin/env bash
set -euo pipefail

# Verifies key docs path references resolve to real files.
# Scope is intentionally targeted to high-signal docs.

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd -- "${SCRIPT_DIR}/../.." && pwd)"

DOCS=(
  "README.md"
  "docs/README.md"
  "docs/00-mvp-truth.md"
  "docs/01-flows.md"
  "docs/02-wireframes.md"
  "docs/03-ux-package.md"
  "docs/ai/reference/REFERENCE_INDEX.md"
)

missing=0

check_path() {
  local source="$1"
  local raw="$2"
  local path="${raw#./}"

  # Skip external URLs, anchors, and obvious non-path tokens.
  case "$path" in
    http://*|https://*|mailto:*|\#*|*://*)
      return 0
      ;;
  esac

  # Keep checks focused on repo-local documentation/code paths.
  case "$path" in
    README.md|docs/*|app/*|tools/*)
      ;;
    *)
      return 0
      ;;
  esac

  if [ ! -e "${REPO_ROOT}/${path}" ]; then
    echo "❌ docs verify: missing path '${path}' referenced in ${source}" >&2
    missing=1
  fi
}

for rel in "${DOCS[@]}"; do
  file="${REPO_ROOT}/${rel}"
  if [ ! -f "$file" ]; then
    echo "❌ docs verify: expected doc not found: ${rel}" >&2
    missing=1
    continue
  fi

  # Backticked paths.
  while IFS= read -r match; do
    token="${match#\`}"
    token="${token%\`}"
    check_path "$rel" "$token"
  done < <(grep -oE '\`[^`]+\`' "$file" || true)

  # Markdown links: [label](path)
  while IFS= read -r match; do
    token="$(printf '%s' "$match" | sed -E 's/^\[[^]]+\]\(([^)]+)\)$/\1/')"
    check_path "$rel" "$token"
  done < <(grep -oE '\[[^]]+\]\([^)]+\)' "$file" || true)
done

if [ "$missing" -ne 0 ]; then
  exit 1
fi

echo "✅ docs verify passed"

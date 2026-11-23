#!/usr/bin/env bash
# Test (issue #835) : le workflow iOS doit installer ImageMagick avant apply_app_identity.sh.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
workflow="$repo/.github/workflows/ios-build.yml"

install_line="$(grep -n 'brew install imagemagick' "$workflow" | head -n 1 | cut -d: -f1)"
identity_line="$(grep -n 'run:.*apply_app_identity.sh ios' "$workflow" | head -n 1 | cut -d: -f1)"
[ -n "$install_line" ] && [ -n "$identity_line" ] && [ "$install_line" -lt "$identity_line" ] \
  || { echo "FAIL: ImageMagick doit être installé avant apply_app_identity.sh ios dans ios-build.yml"; exit 1; }

echo "OK: ImageMagick installé avant apply_app_identity.sh (ios)"

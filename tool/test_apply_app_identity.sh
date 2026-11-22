#!/usr/bin/env bash
# Test de tool/apply_app_identity.sh (issue #751) : exécute le vrai script côté Android
# dans un dossier temporaire et vérifie les icônes produites, puis vérifie que le workflow
# APK installe ImageMagick avant l'étape qui en a besoin.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
script="$repo/tool/apply_app_identity.sh"
workflow="$repo/.github/workflows/apk.yml"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

command -v convert >/dev/null || { echo "FAIL: ImageMagick (convert) absent"; exit 1; }

mkdir -p "$work/assets/images" "$work/android/app/src/main"
cp "$repo/assets/images/app_icon.png" "$work/assets/images/"
cat > "$work/android/app/src/main/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="kahwetne">
    </application>
</manifest>
XML

(cd "$work" && bash "$script" android >/dev/null)

grep -q 'android:label="Korti Fans"' "$work/android/app/src/main/AndroidManifest.xml" \
  || { echo "FAIL: nom Korti Fans non appliqué"; exit 1; }

declare -A sizes=( [mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192 )
for density in "${!sizes[@]}"; do
  png="$work/android/app/src/main/res/mipmap-$density/ic_launcher.png"
  [ -f "$png" ] || { echo "FAIL: icône manquante $png"; exit 1; }
  got="$(identify -format '%wx%h' "$png")"
  want="${sizes[$density]}x${sizes[$density]}"
  [ "$got" = "$want" ] || { echo "FAIL: $density attendu $want, obtenu $got"; exit 1; }
done

# Le workflow doit installer ImageMagick avant l'étape d'identité.
install_line="$(grep -n 'apt-get install.*imagemagick' "$workflow" | head -n 1 | cut -d: -f1)"
identity_line="$(grep -n 'run:.*apply_app_identity.sh' "$workflow" | head -n 1 | cut -d: -f1)"
[ -n "$install_line" ] && [ -n "$identity_line" ] && [ "$install_line" -lt "$identity_line" ] \
  || { echo "FAIL: ImageMagick doit être installé avant apply_app_identity.sh dans apk.yml"; exit 1; }

echo "OK: apply_app_identity.sh (android) et installation ImageMagick vérifiés"

#!/usr/bin/env bash
# Applique le nom « Korti Fans » et l'icône à la plateforme générée par `flutter create` (CI).
# Usage : bash tool/apply_app_identity.sh android|ios
# Source de l'icône : assets/images/app_icon.png
set -euo pipefail

platform="${1:?usage: apply_app_identity.sh android|ios}"
name="Korti Fans"
icon=assets/images/app_icon.png

case "$platform" in
  android)
    manifest=android/app/src/main/AndroidManifest.xml
    sed -i "s/android:label=\"[^\"]*\"/android:label=\"$name\"/" "$manifest"
    declare -A sizes=( [mdpi]=48 [hdpi]=72 [xhdpi]=96 [xxhdpi]=144 [xxxhdpi]=192 )
    for density in "${!sizes[@]}"; do
      dir="android/app/src/main/res/mipmap-$density"
      mkdir -p "$dir"
      convert "$icon" -resize "${sizes[$density]}x${sizes[$density]}" "$dir/ic_launcher.png"
    done
    ;;
  ios)
    plist=ios/Runner/Info.plist
    python3 - "$plist" "$name" <<'PY'
import plistlib, sys
path, name = sys.argv[1], sys.argv[2]
with open(path, 'rb') as f:
    data = plistlib.load(f)
data['CFBundleDisplayName'] = name
data['CFBundleName'] = name
with open(path, 'wb') as f:
    plistlib.dump(data, f)
PY
    set_dir=ios/Runner/Assets.xcassets/AppIcon.appiconset
    for png in "$set_dir"/*.png; do
      px=$(identify -format '%w' "$png")
      convert "$icon" -resize "${px}x${px}" "$png"
    done
    ;;
  *) echo "plateforme inconnue : $platform" >&2; exit 1 ;;
esac
echo "Identité « $name » appliquée ($platform)"

#!/usr/bin/env bash
# Test de tool/patch_ad_app_ids.sh (issue #619) : exécute le vrai script dans un
# dossier temporaire, avec une copie réelle de ads_config.dart, et vérifie les IDs.
set -euo pipefail

repo="$(cd "$(dirname "$0")/.." && pwd)"
script="$repo/tool/patch_ad_app_ids.sh"
work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT

mkdir -p "$work/lib/core/services" "$work/ios/Runner" "$work/android/app/src/main"
cp "$repo/lib/core/services/ads_config.dart" "$work/lib/core/services/"

expected_ios="$(sed -n "s/.*ios = '\([^']*\)'.*/\1/p" "$work/lib/core/services/ads_config.dart" | head -n 1)"
expected_android="$(sed -n "s/.*android = '\([^']*\)'.*/\1/p" "$work/lib/core/services/ads_config.dart" | head -n 1)"
[ -n "$expected_ios" ] && [ -n "$expected_android" ] || { echo "FAIL: ID introuvable dans ads_config.dart"; exit 1; }

cat > "$work/ios/Runner/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0">
<dict>
	<key>CFBundleName</key>
	<string>kahwetne</string>
</dict>
</plist>
PLIST

cat > "$work/android/app/src/main/AndroidManifest.xml" <<'XML'
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:label="kahwetne">
    </application>
</manifest>
XML

# grep BSD (runner macOS) refuse -P : on simule ce comportement pour éviter une régression.
real_grep="$(command -v grep)"
mkdir -p "$work/bin"
cat > "$work/bin/grep" <<SHIM
#!/usr/bin/env bash
for a in "\$@"; do
  case "\$a" in -*P*) echo "grep: invalid option -- P" >&2; exit 2 ;; esac
done
exec "$real_grep" "\$@"
SHIM
chmod +x "$work/bin/grep"
export PATH="$work/bin:$PATH"

cd "$work"
bash "$script" ios >/dev/null
grep -q "<string>$expected_ios</string>" ios/Runner/Info.plist \
  || { echo "FAIL: GADApplicationIdentifier iOS absent"; exit 1; }
grep -q NSUserTrackingUsageDescription ios/Runner/Info.plist \
  || { echo "FAIL: clé ATT absente"; exit 1; }

bash "$script" android >/dev/null
grep -q "android:value=\"$expected_android\"" android/app/src/main/AndroidManifest.xml \
  || { echo "FAIL: App ID Android absent"; exit 1; }

echo "OK : patch_ad_app_ids.sh (ios + android) passe"

#!/usr/bin/env bash
# Ajoute l'App ID AdMob au dossier natif généré par `flutter create` (issue #465).
# Usage : bash tool/patch_ad_app_ids.sh android   |   bash tool/patch_ad_app_ids.sh ios
# La valeur vient de lib/core/services/ads_config.dart (source unique).
set -euo pipefail

platform="${1:?usage: patch_ad_app_ids.sh android|ios}"
cfg=lib/core/services/ads_config.dart

case "$platform" in
  android)
    id=$(grep -oP "android = '\K[^']+" "$cfg")
    file=android/app/src/main/AndroidManifest.xml
    ;;
  ios)
    id=$(grep -oP "ios = '\K[^']+" "$cfg")
    file=ios/Runner/Info.plist
    ;;
  *) echo "plateforme inconnue : $platform" >&2; exit 1 ;;
esac

python3 - "$platform" "$file" "$id" <<'PY'
import sys
platform, path, app_id = sys.argv[1], sys.argv[2], sys.argv[3]
text = open(path, encoding="utf-8").read()
if app_id in text:
    sys.exit(0)  # déjà présent : ne rien faire
if platform == "android":
    tag = ('    <meta-data android:name="com.google.android.gms.ads.APPLICATION_ID"\n'
           f'        android:value="{app_id}"/>\n')
    text = text.replace("</application>", tag + "</application>", 1)
else:
    entry = ("\t<key>GADApplicationIdentifier</key>\n"
             f"\t<string>{app_id}</string>\n")
    idx = text.rindex("</dict>")
    text = text[:idx] + entry + text[idx:]
open(path, "w", encoding="utf-8").write(text)
PY

# Vérification : l'App ID doit être présent, sinon le build échoue ici et pas sur l'appareil.
grep -q "$id" "$file" || { echo "App ID absent de $file" >&2; exit 1; }
echo "App ID AdMob ($platform) présent dans $file"

# Demande ATT iOS (#466) : le texte affiché au joueur est obligatoire, sinon l'app plante à la demande.
if [ "$platform" = ios ] && ! grep -q NSUserTrackingUsageDescription "$file"; then
  python3 - "$file" <<'PY'
import sys
path = sys.argv[1]
text = open(path, encoding="utf-8").read()
entry = ("\t<key>NSUserTrackingUsageDescription</key>\n"
         "\t<string>Pour vous proposer des publicités plus pertinentes.</string>\n")
idx = text.rindex("</dict>")
open(path, "w", encoding="utf-8").write(text[:idx] + entry + text[idx:])
PY
  grep -q NSUserTrackingUsageDescription "$file" || { echo "Clé ATT absente de $file" >&2; exit 1; }
fi

#!/usr/bin/env bash
# Test de tool/merge_coverage.sh : vérifie la somme des compteurs par ligne et les totaux LF/LH.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
script="$root/tool/merge_coverage.sh"
tmp="$(mktemp -d)"
trap 'rm -rf "$tmp"' EXIT

# Shard 1 : lib/a.dart lignes 1 (couverte) et 2 (non) ; lib/b.dart absent.
cat > "$tmp/shard1.info" <<'EOF'
SF:lib/a.dart
DA:1,1
DA:2,0
LF:2
LH:1
end_of_record
EOF

# Shard 2 : lib/a.dart ligne 2 couverte, ligne 3 non ; lib/b.dart ligne 5 non couverte.
cat > "$tmp/shard2.info" <<'EOF'
SF:lib/a.dart
DA:2,3
DA:3,0
end_of_record
SF:lib/b.dart
DA:5,0
end_of_record
EOF

# Attendu : lib/a.dart = lignes 1:1, 2:3, 3:0 (3 lignes, 2 couvertes) ; lib/b.dart = ligne 5:0.
cat > "$tmp/expected.info" <<'EOF'
TN:
SF:lib/a.dart
DA:1,1
DA:2,3
DA:3,0
LF:3
LH:2
end_of_record
SF:lib/b.dart
DA:5,0
LF:1
LH:0
end_of_record
EOF

bash "$script" "$tmp/merged.info" "$tmp/shard1.info" "$tmp/shard2.info"

if ! diff -u "$tmp/expected.info" "$tmp/merged.info"; then
  echo "ÉCHEC : la fusion de couverture ne correspond pas au résultat attendu." >&2
  exit 1
fi

# Fichier introuvable : le script doit échouer.
if bash "$script" "$tmp/x.info" "$tmp/absent.info" 2>/dev/null; then
  echo "ÉCHEC : un fichier d'entrée absent devrait faire échouer le script." >&2
  exit 1
fi

echo "OK : fusion de couverture conforme."

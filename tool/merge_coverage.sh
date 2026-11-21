#!/usr/bin/env bash
# Fusionne les fichiers lcov produits par chaque shard de tests (CI) en un seul fichier.
# Une ligne est couverte si au moins un shard l'a exécutée : les compteurs DA sont sommés par fichier et par ligne.
# Usage : bash tool/merge_coverage.sh SORTIE.info ENTREE1.info [ENTREE2.info ...]
set -euo pipefail

if [ "$#" -lt 2 ]; then
  echo "Usage: $0 SORTIE ENTREE..." >&2
  exit 2
fi

out="$1"
shift
for f in "$@"; do
  if [ ! -f "$f" ]; then
    echo "Fichier introuvable : $f" >&2
    exit 1
  fi
done

export LC_ALL=C

{
  awk '
    /^SF:/ { file = substr($0, 4); next }
    /^DA:/ {
      split(substr($0, 4), p, ",")
      count[file "\t" p[1]] += p[2]
    }
    END {
      for (k in count) print k "\t" count[k]
    }
  ' "$@" | sort -t$'\t' -k1,1 -k2,2n | awk -F'\t' '
    function close_record() {
      print "LF:" lf
      print "LH:" lh
      print "end_of_record"
    }
    BEGIN { print "TN:" }
    $1 != current {
      if (current != "") close_record()
      current = $1
      print "SF:" current
      lf = 0
      lh = 0
    }
    {
      print "DA:" $2 "," $3
      lf++
      if ($3 > 0) lh++
    }
    END {
      if (current != "") close_record()
    }
  '
} > "$out"

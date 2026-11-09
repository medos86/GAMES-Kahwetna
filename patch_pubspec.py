# Ajoute les assets (images, icônes) à la section flutter: de pubspec.yaml, sans toucher au reste.
# Usage : python3 patch_pubspec.py  (à lancer dans ~/Documents/projects/kahwetne_flutter)
import re, sys

path = "pubspec.yaml"
text = open(path, encoding="utf-8").read()
if "- assets/images/" in text:
    print("pubspec.yaml : assets/images/ déjà déclaré, rien à faire.")
    sys.exit(0)

block = "  assets:\n    - assets/images/\n    - assets/icons/\n    - assets/sounds/domino/\n"
new, n = re.subn(r"(?m)^(flutter:\s*\n)", r"\1" + block.replace("\\", "\\\\"), text, count=1)
if n == 0:
    print("ERREUR : pas de section 'flutter:' dans pubspec.yaml")
    sys.exit(1)
open(path, "w", encoding="utf-8").write(new)
print("pubspec.yaml : assets/images/ et assets/icons/ ajoutés.")

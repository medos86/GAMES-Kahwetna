# Kahwetne Flutter — étape 3 (menu principal et logique du Domino)

Contenu :
- le menu principal (étape 2) ;
- la logique du Domino en Dart pur (`lib/game/`), vérifiée contre le code TypeScript.

## Mise en place sur votre Mac

Le projet doit déjà exister (`flutter create`) et contenir `pubspec.yaml`.

```bash
cd ~/Documents/projects/kahwetne_flutter
flutter pub add shared_preferences flutter_svg audioplayers
flutter pub add --dev fake_async
# Copier lib/, test/, assets/ de l'archive, puis remplacer la section flutter: de pubspec.yaml
# par PUBSPEC_FLUTTER_SECTION.yaml

flutter pub get
flutter analyze
flutter test                    # tous les tests : layout, parité Domino, règles
flutter run                     # menu principal
flutter run --dart-define=PROBE=true   # écran de contrôle des tailles
```

## Tests

- `test/layout/` : règles de taille (formules CSS du source).
- `test/parity/domino_parity_test.dart` : rejoue 8 parties de référence (245 actions) générées par le
  vrai code `domino.ts`. Pour chaque action, il compare l'état complet et l'identité du retour.
  Le hasard est enregistré côté TypeScript et rejoué côté Dart, donc les donnes sont identiques.
- Les fixtures sont dans `test/parity/fixtures/domino_parity.json`.

Vérification faite ici : un portage Python ligne à ligne de `lib/game/domino.dart` reproduit les
245 étapes sans écart. La compilation Dart n'a pas pu être exécutée : `flutter test` est à lancer sur votre Mac.

## Plateformes : Android, iOS et web

Le projet vise les trois. Le dossier `web/` s'ajoute à un projet existant, sans toucher à `android/` ni `ios/` :

```bash
cd ~/Documents/projects/kahwetne_flutter
flutter create . --platforms=android,ios,web --org com.kahwetne --project-name kahwetne
flutter run -d chrome                 # web
flutter run -d <id_android_ou_ios>    # appareil mobile (liste : flutter devices)
flutter build web                     # build web de production, dans build/web/
```

Points à vérifier sur le web :
- `shared_preferences` stocke le mode sans pub dans le navigateur (équivalent de `localStorage` du React).
- Les polices et l'image sont chargées comme assets, comme sur mobile.
- Le web est un build Flutter, pas le React : le rendu peut différer légèrement (rendu du texte, flou).
- Le format « téléphone » se teste dans Chrome avec les outils de développement (mode appareil), à 360 ou 393 px de large.

## Portrait et plein écran : réglages natifs

`lib/main.dart` fixe déjà le portrait et le mode immersif (barre Android masquée) au démarrage.
Pour que le verrouillage soit aussi appliqué par le système dès l'ouverture, ajoutez ces réglages sur votre Mac :

**iOS** : dans `ios/Runner/Info.plist`, ne gardez que le portrait pour l'iPhone :
```xml
<key>UISupportedInterfaceOrientations</key>
<array>
    <string>UIInterfaceOrientationPortrait</string>
</array>
```

**Android** : dans `android/app/src/main/AndroidManifest.xml`, sur la balise `<activity>` principale :
```xml
android:screenOrientation="portrait"
```

## Contenu du projet

- `lib/features/menu/` : le menu (deux écrans, liste des jeux, niveau et score, mode sans pub).
- `lib/game/common.dart` : joueurs et `other()`.
- `lib/game/domino.dart` : donne, pose, pioche, passe, fin de manche (même ordre que `domino.ts`).
- `lib/widgets/` : effet d'appui et apparition progressive.
- `assets/icons/*.svg` : les cinq icônes de jeu.
- `lib/core/layout/device_metrics.dart` : règles de taille.

## Ce qui reste à faire

- Ce portage du Domino ne couvre pas encore l'IA (`aiStep` du source, à mettre dans le contrôleur de l'écran),
  ni l'écran de jeu. Le fichier `domino.dart` ne contient que les règles.
- `fromJson` n'est pas encore écrit (le guide le demande pour la sauvegarde) ; `toJson` suffit pour les tests.
- Le hasard utilise `RandomDouble` (un double dans [0, 1[), comme `Math.random` : c'est ce qui permet la parité.

## Limites d'approximation (menu, à valider sur captures)

- Flou de fond approximé (sigma 12) ; sépia et rotation de teinte du fond non reproduits ; motif de points omis.
- Chiffres 7, 8 et 9 des icônes SVG : `flutter_svg` ne rend pas toujours le texte. À superposer en `Text` si besoin.
- Noms d'icônes Lucide (`LucideIcons.cloudSun`, etc.) à vérifier dans la version installée.

## Fichiers à fournir (non inclus dans l'archive)

- `assets/images/background.webp` : copié depuis `src/imports/Gemini_Generated_Image_.jpeg` du projet React.
- Polices dans `assets/fonts/` : Nunito, Roboto Slab, Bowlby One SC (Google Fonts, licence OFL), aux noms de `PUBSPEC_FLUTTER_SECTION.yaml`.

## Écran d'ouverture et fond

- `lib/features/splash/splash_screen.dart` : écran d'ouverture (fond du village, titre, « Touchez pour commencer »),
  puis passage au menu après environ 2,4 s, ou dès l'appui.
- Le même fond (`assets/images/background.webp`) sert à l'ouverture, au menu principal et au choix du niveau.
- Les voiles colorés par niveau (facile, moyen, difficile) restent appliqués sur le menu.

## Sons

- Dépendance : `flutter pub add audioplayers`.
- Ajoutez `- assets/sounds/domino/` sous `assets:` dans `pubspec.yaml` (voir `patch_pubspec.py`).
- Déposez `place.mp3`, `draw.mp3`, `pass.mp3`, `win.mp3`, `lose.mp3` dans `assets/sounds/domino/` (voir `assets/sounds/domino/LISEZMOI.txt`).
- Les sons sont déclenchés par `lib/core/audio/sounds.dart` depuis le contrôleur du Domino. Sans fichiers, le jeu reste silencieux.

## Style cartoon (interrupteur)

- `lib/core/theme/game_style.dart` contient `kCartoonStyle`.
  - `true` : tapis bleu, bordure zellige, cadre terracotta, accents magenta et jaune (style actuel).
  - `false` : retour au style d'origine du jeu React (tapis vert, cadre brun, bannières jaune-orange et sky-indigo).
- Pour annuler : remplacez `true` par `false`, puis relancez l'application.
- L'écran Chkobba ouvert depuis le menu est un aperçu du tapis (`lib/features/chkobba/`). La logique du jeu n'est pas encore portée.

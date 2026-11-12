# Kahwetne Flutter

Portage Flutter des jeux de cartes kahwetne (Chkobba, Domino, Belote/Coinche, Ludo, Rami), à partir de la version React.

## État d'avancement

| Jeu | Règles | IA | Écran | Tests |
|---|---|---|---|---|
| Domino | `lib/game/domino.dart` | `lib/game/domino_ai.dart`, pilotée par `domino_controller.dart` | `domino_screen.dart` | parité TS ↔ Dart (`test/parity/`) |
| Chkobba | `lib/game/chkobba.dart` | `chooseOpponentMove` (niveaux facile, moyen, difficile) | `chkobba_screen.dart`, règles dans `chkobba_rules_screen.dart` | `test/game/chkobba_test.dart`, `test/features/chkobba_*` |
| Belote (Coinche) | `lib/game/coinche.dart` | `chooseBid` et jeu de carte par niveau | `coinche_screen.dart` | `test/game/coinche_test.dart`, `test/features/coinche_controller_test.dart` |
| Ludo | `lib/game/ludo.dart` | `chooseMove` par niveau | `ludo_screen.dart`, `ludo_layout.dart` | `test/game/ludo_test.dart`, `test/features/ludo_*` |
| Rami | `lib/game/rami.dart` | `aiStep` par niveau | `rami_screen.dart` | `test/game/rami_test.dart`, `test/features/rami_controller_test.dart` |

La parité TS ↔ Dart n'existe que pour le Domino, et les fixtures sont figées : le projet React n'est plus maintenu, la référence est désormais l'app Flutter elle-même.

## Mise en place

Le projet doit déjà exister (`flutter create`) et contenir `pubspec.yaml`.

```bash
cd ~/Documents/projects/kahwetne_flutter
flutter pub add shared_preferences flutter_svg flutter_soloud
flutter pub add --dev fake_async
# Copier lib/, test/, assets/ dans le projet, puis adapter la section flutter: de pubspec.yaml
# (voir pubspec.yaml et PUBSPEC_FLUTTER_SECTION.yaml)

flutter pub get
flutter analyze
flutter test
flutter run                            # menu principal
flutter run --dart-define=PROBE=true   # écran de contrôle des tailles
```

La CI (`.github/workflows/analyze.yml`) lance `flutter analyze` et `flutter test` à chaque push et pull request.

## Dépendances

Ce que déclare `pubspec.yaml` et ce que le code utilise :

| Paquet | Rôle |
|---|---|
| `flutter_soloud` | effets sonores (`lib/core/audio/sounds.dart`, fichiers `.wav`) |
| `flutter_svg` | icônes des jeux (`assets/icons/*.svg`) |
| `shared_preferences` | mode sans pub (équivalent du `localStorage` du React) |
| `fake_async` (dev) | tests des contrôleurs avec minuteurs |

Écarts volontaires avec le guide, qui prévoyait quatre paquets de plus :

- `go_router` : non adopté. L'application garde le `Navigator` de Flutter avec une seule table de routes
  (`lib/app/game_routes.dart`, qui reprend le format des chemins de React Router).
- `flutter_animate` : non adopté. Les animations passent par `lib/widgets/` (`fade_slide_in.dart`, `pressable.dart`).
- `collection` : non nécessaire. Le tri stable et le mélange sont dans `lib/core/utils/js_compat.dart`.
- `lucide_icons_flutter` : non adopté. Les icônes sont des SVG locaux.

Si l'un de ces paquets est adopté plus tard, l'ajouter à `pubspec.yaml` et mettre à jour ce tableau dans le même commit.

## Tests

- `test/layout/` : règles de taille (formules CSS du source).
- `test/parity/domino_parity_test.dart` : test de non-régression. Rejoue 8 parties (245 actions) enregistrées
  à partir de l'ancien code `domino.ts`, et compare l'état complet et l'identité du retour à chaque action.
  Le hasard est rejoué depuis les tirages enregistrés. Les fixtures ne sont plus régénérées : si une règle
  Domino change volontairement, mettre à jour le JSON dans le même commit.
- Les fixtures sont dans `test/parity/fixtures/domino_parity.json`.
- `test/game/` : règles pures de chaque jeu. `test/features/` : contrôleurs et widgets.

## Plateformes : Android, iOS et web

Le dépôt ne contient ni `android/`, ni `ios/`, ni `web/` : ils sont générés par `flutter create` sur votre machine.

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
Pour que le verrouillage soit aussi appliqué par le système dès l'ouverture, ajoutez ces réglages :

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

- `lib/app/game_routes.dart` : table des routes des écrans de jeu.
- `lib/features/menu/` : le menu (liste des jeux, niveau et score, mode sans pub).
- `lib/features/splash/` : écran d'ouverture.
- `lib/game/` : règles et IA de chaque jeu, en Dart pur. `common.dart` contient les joueurs et `other()`.
- `lib/features/<jeu>/` : écran, contrôleur et rendu des cartes ou pions.
- `lib/widgets/` : effet d'appui et apparition progressive.
- `lib/core/layout/device_metrics.dart` : règles de taille.
- `assets/icons/*.svg` : les cinq icônes de jeu.

## Ce qui reste à faire

- Les sons ne sont fournis que pour le Domino (voir la section Sons).
- Polices : Nunito et Bowlby One SC sont utilisées dans le code et déclarées dans `PUBSPEC_FLUTTER_SECTION.yaml`, mais leurs fichiers ne sont pas dans `assets/fonts/`. Seule Roboto Slab est présente.
- Le hasard utilise `RandomDouble` (un double dans [0, 1[), comme `Math.random` : c'est ce qui permet la parité.

## Limites d'approximation (menu, à valider sur captures)

- Flou de fond approximé (sigma 12) ; sépia et rotation de teinte du fond non reproduits ; motif de points omis.
- Chiffres 7, 8 et 9 des icônes SVG : `flutter_svg` ne rend pas toujours le texte. À superposer en `Text` si besoin.

## Fichiers à fournir (non inclus dans le dépôt)

- Polices Nunito et Bowlby One SC dans `assets/fonts/` (Google Fonts, licence OFL), aux noms de `PUBSPEC_FLUTTER_SECTION.yaml`.

## Écran d'ouverture et fond

Décision (issue #34) : l'écran d'ouverture est **conservé**, bien qu'il n'existe pas dans l'app React qui ouvre directement le menu.
Motif : il donne au lancement une identité visuelle propre au portage (fond du village, titre) et laisse le joueur démarrer d'un appui.
Pour le retirer, supprimer `splash_screen.dart` et pointer l'accueil vers le menu dans `lib/main.dart`.

- `lib/features/splash/splash_screen.dart` : écran d'ouverture (fond du village, titre, « Touchez pour commencer »),
  puis passage au menu après environ 2,4 s, ou dès l'appui.
- Le même fond (`assets/images/background.webp`) sert à l'ouverture, au menu principal et au choix du niveau.
- Les voiles colorés par niveau (facile, moyen, difficile) restent appliqués sur le menu.

## Sons

- Dépendance : `flutter_soloud` (`flutter pub add flutter_soloud`), faible latence pour les effets.
- Les sons sont déclenchés par `lib/core/audio/sounds.dart`, qui charge uniquement `assets/sounds/domino/<nom>.wav`.
- Fichiers attendus : `place.wav`, `draw.wav`, `pass.wav`, `win.wav`, `lose.wav` (voir `assets/sounds/domino/LISEZMOI.txt`).
- Le dossier `assets/sounds/domino/` doit être déclaré sous `assets:` dans `pubspec.yaml` (`patch_pubspec.py` peut le faire).
- Sans fichiers, le jeu reste silencieux. Les autres jeux n'ont pas encore de sons (issue #24).

## Style cartoon (interrupteur)

- `lib/core/theme/game_style.dart` contient `kCartoonStyle`.
  - `true` : tapis bleu, bordure zellige, cadre terracotta, accents magenta et jaune.
  - `false` : style d'origine du jeu React (tapis vert, cadre brun, bannières jaune-orange et sky-indigo).
- Réglage actuel : `false`. Pour le style cartoon, remplacez `false` par `true`, puis relancez l'application.

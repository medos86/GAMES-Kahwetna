// Captures d'écran des écrans (issue #185).
//
// Ne tourne que si --dart-define=SCREENS=... est fourni, donc il est ignoré par
// `flutter test` dans analyze.yml. Lancement : voir .github/workflows/screenshots.yml.
//   SCREENS=all            : tous les écrans
//   SCREENS=menu,settings  : une liste choisie
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_theme.dart';
import 'package:kahwetne/features/menu/main_menu_screen.dart';
import 'package:kahwetne/features/settings/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _selected = String.fromEnvironment('SCREENS');

bool _want(String name) {
  if (_selected.isEmpty) return false;
  if (_selected == 'all') return true;
  return _selected.split(',').map((s) => s.trim()).contains(name);
}

// Format téléphone (390 x 844 points), rendu en 3x.
const _logicalSize = Size(390, 844);
const _pixelRatio = 3.0;

// Polices de l'app (pubspec.yaml), chargées à la main : sans elles, les captures
// affichent la police de test (blocs carrés).
const _fonts = {
  'Nunito': [
    'assets/fonts/Nunito-400.ttf',
    'assets/fonts/Nunito-600.ttf',
    'assets/fonts/Nunito-700.ttf',
    'assets/fonts/Nunito-800.ttf',
    'assets/fonts/Nunito-900.ttf',
  ],
  'RobotoSlab': [
    'assets/fonts/RobotoSlab-Regular.ttf',
    'assets/fonts/RobotoSlab-600.ttf',
    'assets/fonts/RobotoSlab-Bold.ttf',
    'assets/fonts/RobotoSlab-800.ttf',
    'assets/fonts/RobotoSlab-900.ttf',
  ],
  'BowlbyOneSC': ['assets/fonts/BowlbyOneSC-Regular.ttf'],
  'Bangers': ['assets/fonts/Bangers-Regular.ttf'],
  'Tajawal': [
    'assets/fonts/Tajawal-Regular.ttf',
    'assets/fonts/Tajawal-Bold.ttf',
    'assets/fonts/Tajawal-ExtraBold.ttf',
  ],
};

Future<void> _loadAppFonts() async {
  for (final entry in _fonts.entries) {
    final loader = FontLoader(entry.key);
    for (final file in entry.value) {
      loader.addFont(rootBundle.load(file));
    }
    await loader.load();
  }
}

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await _loadAppFonts();
  });

  final screens = <String, Widget>{
    'menu': const MainMenuScreen(),
    'settings': const SettingsScreen(),
  };

  for (final entry in screens.entries) {
    testWidgets('capture ${entry.key}', (tester) async {
      tester.view.physicalSize = _logicalSize * _pixelRatio;
      tester.view.devicePixelRatio = _pixelRatio;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: buildComicTheme(),
          home: entry.value,
        ),
      );
      // Un délai fixe plutôt que pumpAndSettle : les animations en boucle ne se terminent jamais.
      await tester.pump(const Duration(seconds: 1));

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile('goldens/${entry.key}.png'),
      );
    }, skip: !_want(entry.key));
  }
}

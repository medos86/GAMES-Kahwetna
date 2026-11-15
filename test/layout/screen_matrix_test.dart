import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_screen.dart';
import 'package:kahwetne/features/coinche/coinche_screen.dart';
import 'package:kahwetne/features/domino/domino_screen.dart';
import 'package:kahwetne/features/ludo/ludo_screen.dart';
import 'package:kahwetne/features/menu/menu_models.dart';
import 'package:kahwetne/features/rami/rami_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Matrice de mise en page (#337) : chaque écran se rend sans dépassement
// (RenderFlex overflow) sur plusieurs appareils, avec une échelle de texte
// élevée et une encoche simulée.

class _Device {
  const _Device(this.name, this.size, {this.topInset = 0});

  final String name;
  final Size size;
  final double topInset;
}

const _devices = <_Device>[
  _Device('Galaxy S24', Size(360, 780)),
  _Device('iPhone 15', Size(393, 852), topInset: 59),
  _Device('iPhone SE', Size(375, 667)),
  _Device('Petit écran', Size(320, 568)),
  _Device('Tablette', Size(768, 1024)),
  _Device('Paysage', Size(852, 393)),
];

const _textScales = <double>[1.0, 1.3, 2.0];

final _screens = <String, Widget Function()>{
  'Rami': () {
    return const RamiScreen(difficulty: Difficulty.facile, targetScore: 100);
  },
  'Coinche': () {
    return const CoincheScreen(
      difficulty: Difficulty.facile,
      targetScore: 1000,
    );
  },
  'Domino': () {
    return const DominoScreen(difficulty: Difficulty.facile, targetScore: 100);
  },
  'Ludo': () {
    return const LudoScreen(difficulty: Difficulty.facile, players: 2);
  },
  'Chkobba': () {
    return const ChkobbaScreen(difficulty: Difficulty.facile, targetScore: 11);
  },
};

// Dépassements connus, suivis dans #340 : à retirer au fur et à mesure
// de leur correction. Toute autre combinaison en échec bloque la CI.
// TEMP (#340) : false = toutes les combinaisons s'exécutent en CI.
const _skipKnown = false;

const _knownOverflows = <String>{
  'Chkobba · Galaxy S24 · texte x1.0',
  'Chkobba · Galaxy S24 · texte x1.3',
  'Chkobba · Galaxy S24 · texte x2.0',
  'Chkobba · Paysage · texte x1.3',
  'Chkobba · Paysage · texte x2.0',
  'Chkobba · Petit écran · texte x1.0',
  'Chkobba · Petit écran · texte x1.3',
  'Chkobba · Petit écran · texte x2.0',
  'Chkobba · Tablette · texte x1.3',
  'Chkobba · Tablette · texte x2.0',
  'Chkobba · iPhone 15 · texte x1.3',
  'Chkobba · iPhone 15 · texte x2.0',
  'Chkobba · iPhone SE · texte x1.3',
  'Chkobba · iPhone SE · texte x2.0',
  'Coinche · Galaxy S24 · texte x1.3',
  'Coinche · Galaxy S24 · texte x2.0',
  'Coinche · Paysage · texte x1.0',
  'Coinche · Paysage · texte x1.3',
  'Coinche · Paysage · texte x2.0',
  'Coinche · Petit écran · texte x1.0',
  'Coinche · Petit écran · texte x1.3',
  'Coinche · Petit écran · texte x2.0',
  'Coinche · Tablette · texte x1.3',
  'Coinche · Tablette · texte x2.0',
  'Coinche · iPhone 15 · texte x1.3',
  'Coinche · iPhone 15 · texte x2.0',
  'Coinche · iPhone SE · texte x1.3',
  'Coinche · iPhone SE · texte x2.0',
  'Domino · Galaxy S24 · texte x1.3',
  'Domino · Galaxy S24 · texte x2.0',
  'Domino · Paysage · texte x1.0',
  'Domino · Paysage · texte x1.3',
  'Domino · Paysage · texte x2.0',
  'Domino · Petit écran · texte x1.3',
  'Domino · Petit écran · texte x2.0',
  'Domino · Tablette · texte x1.3',
  'Domino · Tablette · texte x2.0',
  'Domino · iPhone 15 · texte x1.3',
  'Domino · iPhone 15 · texte x2.0',
  'Domino · iPhone SE · texte x1.3',
  'Domino · iPhone SE · texte x2.0',
  'Ludo · Galaxy S24 · texte x1.3',
  'Ludo · Galaxy S24 · texte x2.0',
  'Ludo · Paysage · texte x1.0',
  'Ludo · Paysage · texte x1.3',
  'Ludo · Paysage · texte x2.0',
  'Ludo · Petit écran · texte x1.0',
  'Ludo · Petit écran · texte x1.3',
  'Ludo · Petit écran · texte x2.0',
  'Ludo · Tablette · texte x1.3',
  'Ludo · Tablette · texte x2.0',
  'Ludo · iPhone 15 · texte x1.3',
  'Ludo · iPhone 15 · texte x2.0',
  'Ludo · iPhone SE · texte x1.3',
  'Ludo · iPhone SE · texte x2.0',
  'Rami · Galaxy S24 · texte x1.0',
  'Rami · Galaxy S24 · texte x1.3',
  'Rami · Galaxy S24 · texte x2.0',
  'Rami · Paysage · texte x1.3',
  'Rami · Paysage · texte x2.0',
  'Rami · Petit écran · texte x1.0',
  'Rami · Petit écran · texte x1.3',
  'Rami · Petit écran · texte x2.0',
  'Rami · Tablette · texte x1.3',
  'Rami · Tablette · texte x2.0',
  'Rami · iPhone 15 · texte x1.3',
  'Rami · iPhone 15 · texte x2.0',
  'Rami · iPhone SE · texte x1.3',
  'Rami · iPhone SE · texte x2.0',
};

Future<void> _pump(
  WidgetTester tester,
  _Device device,
  double textScale,
  Widget screen,
) async {
  tester.view.physicalSize = device.size * 3;
  tester.view.devicePixelRatio = 3;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      builder: (context, child) {
        final media = MediaQuery.of(context);
        final inset = EdgeInsets.only(top: device.topInset);
        return MediaQuery(
          data: media.copyWith(
            textScaler: TextScaler.linear(textScale),
            padding: inset,
            viewPadding: inset,
          ),
          child: child!,
        );
      },
      home: screen,
    ),
  );
  await tester.pump(const Duration(seconds: 1));

  final error = tester.takeException();
  if (error != null) {
    fail('${device.name}, texte x$textScale : $error');
  }

  // Démontage : annule les minuteurs des contrôleurs et des bannières.
  await tester.pumpWidget(const SizedBox());
  await tester.pump();
}

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final device in _devices) {
    for (final scale in _textScales) {
      for (final entry in _screens.entries) {
        final name = '${entry.key} · ${device.name} · texte x$scale';
        testWidgets(
          name,
          (tester) => _pump(tester, device, scale, entry.value()),
          skip: _skipKnown && _knownOverflows.contains(name),
        );
      }
    }
  }
}

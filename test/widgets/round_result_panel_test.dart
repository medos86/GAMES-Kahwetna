import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/widgets/result_dialog.dart';
import 'package:kahwetne/widgets/round_result_panel.dart';

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: SingleChildScrollView(child: child)),
    ),
  );
}

/// Écran de fin Rami type : 4 lignes, dont un +100 et un gagnant (issue #526).
Widget _ramiLike({VoidCallback? onTap}) {
  return RoundResultPanel(
    title: 'TOI gagne la manche',
    badge: 'MANCHE 1',
    rows: const [
      RoundResultRow(
        name: 'TOI',
        color: ComicPalette.tunisBlue,
        value: '-10',
        reason: 'Gagnant',
        total: '90',
        highlight: true,
      ),
      RoundResultRow(
        name: 'ALI',
        color: ComicPalette.red,
        value: '+100',
        reason: 'Pas ouvert',
        total: '100',
      ),
      RoundResultRow(
        name: 'KARIM',
        color: Color(0xFF2E9E5B),
        value: '+100',
        reason: 'Cartes en main',
        total: '100',
      ),
      RoundResultRow(
        name: 'SAMI',
        color: ComicPalette.yellow,
        value: '+10',
        total: '100',
      ),
    ],
    actions: [
      TextButton(
        onPressed: onTap ?? () {},
        child: const Text('Manche suivante'),
      ),
    ],
  );
}

void main() {
  test('signedScore : signe explicite, 0 sans signe', () {
    expect(signedScore(100), '+100');
    expect(signedScore(-10), '-10');
    expect(signedScore(0), '0');
  });

  test('RoundResultColors : quatre couleurs distinctes, puis cycle', () {
    final colors = {for (var i = 0; i < 4; i++) RoundResultColors.seat(i)};
    expect(colors.length, 4);
    expect(RoundResultColors.seat(4), RoundResultColors.seat(0));
  });

  test('textOn : encre sur jaune, blanc sur bleu', () {
    expect(RoundResultColors.textOn(ComicPalette.yellow), ComicPalette.ink);
    expect(RoundResultColors.textOn(ComicPalette.tunisBlue), Colors.white);
  });

  testWidgets('ligne : nom, valeur, motif et total', (tester) async {
    await tester.pumpWidget(
      _host(
        const RoundResultRow(
          name: 'TOI',
          color: ComicPalette.tunisBlue,
          value: '-10',
          reason: 'Gagnant',
          total: '90',
        ),
      ),
    );

    expect(find.text('TOI'), findsOneWidget);
    expect(find.text('-10'), findsOneWidget);
    expect(find.text('Gagnant'), findsOneWidget);
    expect(find.text('Total 90'), findsOneWidget);
    expect(find.text('T'), findsOneWidget); // initiale dans la pastille
  });

  testWidgets('ligne sans total ni motif (Ludo)', (tester) async {
    await tester.pumpWidget(
      _host(
        const RoundResultRow(
          name: 'Bleu',
          color: ComicPalette.tunisBlue,
          leading: '1',
          value: '1er',
        ),
      ),
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('1er'), findsOneWidget);
    expect(find.textContaining('Total'), findsNothing);
  });

  testWidgets('panneau : bande, badge, lignes et action', (tester) async {
    var taps = 0;
    await tester.pumpWidget(_host(_ramiLike(onTap: () => taps++)));

    expect(find.text('TOI gagne la manche'), findsOneWidget);
    expect(find.text('MANCHE 1'), findsOneWidget);
    expect(find.text('ALI'), findsOneWidget);
    expect(find.text('Total 100'), findsWidgets);
    expect(
      tester.widget<ResultDialog>(find.byType(ResultDialog)).accent,
      ComicPalette.yellow,
    );

    await tester.tap(find.text('Manche suivante'));
    expect(taps, 1);
  });

  testWidgets('panneau : sous-titre affiché', (tester) async {
    await tester.pumpWidget(
      _host(
        const RoundResultPanel(
          title: 'Victoire !',
          badge: 'PARTIE TERMINÉE',
          subtitle: 'Objectif : 11 points',
          rows: [],
          actions: [],
        ),
      ),
    );

    expect(find.text('Objectif : 11 points'), findsOneWidget);
    expect(find.text('PARTIE TERMINÉE'), findsOneWidget);
  });

  testWidgets('panneau tient sur 320 px sans débordement', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_host(_ramiLike()));

    // Un débordement lèverait une FlutterError : rien d'autre à vérifier.
    expect(tester.takeException(), isNull);
    expect(find.text('+100'), findsNWidgets(2));
  });
}

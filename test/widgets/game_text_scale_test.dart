import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/widgets/game_scaffold.dart';

// Les écrans de jeu gardent une mise en page fixe : le texte n'est pas agrandi
// au-delà de 1.0, comme dans la majorité des jeux (#344).
void main() {
  testWidgets('GameScaffold ramène l\'échelle de texte à 1.0 maximum', (
    tester,
  ) async {
    late double seen;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: GameScaffold(
            showAd: false,
            child: Builder(
              builder: (context) {
                seen = MediaQuery.textScalerOf(context).scale(10);
                return const SizedBox();
              },
            ),
          ),
        ),
      ),
    );
    expect(seen, 10);
  });

  test('l\'échelle de jeu vaut 1.0', () {
    expect(GameScaffold.maxGameTextScale, 1);
  });
}

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/widgets/comic/comic_panel.dart';
import 'package:kahwetne/widgets/game_header.dart';

// Bouton retour des jeux : même contour bleu que le bouton retour du menu (#360).
void main() {
  testWidgets(
    'le bouton retour des jeux a le contour bleu du menu',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: GameHeader(onMenu: () {})),
        ),
      );
      final finder = find.descendant(
        of: find.byType(GameHeader),
        matching: find.byType(ComicPanel),
      );
      final panel = tester.widget<ComicPanel>(finder.first);
      expect(panel.outlineColor, ComicPalette.tunisBlue);
    },
  );
}

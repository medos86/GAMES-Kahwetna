// Écran des règles de la Chkobba : titre et six sections du source (Rules.tsx).
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/chkobba/chkobba_rules_screen.dart';

void main() {
  testWidgets('affiche le titre et les six sections', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ChkobbaRulesScreen()));

    expect(find.text('Règles de la Chkobba'), findsOneWidget);
    for (final title in [
      '🎴 Le Jeu',
      '🎯 Objectif',
      '📋 Distribution',
      '🎮 Comment Jouer',
      '🏆 Points',
      '💎 Valeurs des Cartes',
    ]) {
      expect(find.text(title), findsOneWidget, reason: title);
    }
    expect(find.text('Retour au Menu'), findsOneWidget);
  });
}

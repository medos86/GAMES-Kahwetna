import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/theme/comic_palette.dart';
import 'package:kahwetne/core/theme/scoba_palette.dart';

/// Tapis et décor de table communs (issues #632 à #635).
/// Palette BD de #634 : tapis vert franc, encre noire, bois commun aux jeux de cartes.

/// Couleurs d'origine (React) encore à éviter dans les tables de jeu.
const _legacyTableColors = ['0xFF10B981', '0xFF4A2A10', '0xFF8B4513'];

/// Dossiers couverts par le garde-fou (Ludo hors périmètre, voir #635).
const _tableDirs = [
  'lib/features/rami',
  'lib/features/coinche',
  'lib/features/domino',
  'lib/features/chkobba',
  'lib/widgets',
];

void main() {
  test('texte encre sur tapis vert : contraste WCAG AA', () {
    expect(
      contrastRatio(ComicPalette.ink, ComicPalette.felt),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('texte encre sur or : contraste WCAG AA', () {
    expect(
      contrastRatio(ComicPalette.ink, ComicPalette.gold),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('compteur blanc sur étiquette encre (pile gagnée) : WCAG AA', () {
    expect(
      contrastRatio(ComicPalette.white, ComicPalette.ink),
      greaterThanOrEqualTo(4.5),
    );
  });

  test('le tapis de Chkobba est le même vert que les autres jeux', () {
    expect(ScobaPalette.tapisVert, ComicPalette.felt);
  });

  test('plus de couleur de table d\'origine écrite en dur', () {
    final found = <String>[];
    for (final dir in _tableDirs) {
      final files = Directory(dir).listSync(recursive: true).whereType<File>();
      for (final file in files) {
        if (!file.path.endsWith('.dart')) {
          continue;
        }
        final text = file.readAsStringSync().toUpperCase();
        for (final hex in _legacyTableColors) {
          if (text.contains(hex)) found.add('${file.path} ($hex)');
        }
      }
    }
    expect(found, isEmpty, reason: found.join('\n'));
  });

  test('aucune image de fond orpheline dans assets/images', () {
    final code = Directory('lib')
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) => f.path.endsWith('.dart'))
        .map((f) => f.readAsStringSync())
        .join('\n');
    final backgrounds = Directory('assets/images')
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (f) => f.path.contains('background') || f.path.contains('game_bg'),
        );
    for (final image in backgrounds) {
      final name = image.uri.pathSegments.last;
      expect(
        code,
        contains(name),
        reason: 'image non référencée : ${image.path}',
      );
    }
  });
}

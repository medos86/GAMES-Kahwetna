import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_card_view.dart';
import 'package:kahwetne/game/coinche.dart';

void main() {
  group('coincheCardAsset (cartes Rami)', () {
    test('chaque carte Coinche (32) a une image Rami unique qui existe', () {
      final assets = <String>{};
      for (final suit in CoincheSuit.values) {
        for (final rank in CoincheRank.values) {
          final card = CoincheCard(
            suit: suit,
            rank: rank,
            id: '${suit.name}-${rank.label}',
          );
          final path = coincheCardAsset(card);
          expect(path, startsWith('assets/images/cards_rami/'));
          expect(File(path).existsSync(), isTrue, reason: path);
          assets.add(path);
        }
      }
      expect(assets, hasLength(32));
    });

    test('mapping des valeurs et couleurs', () {
      CoincheCard c(CoincheSuit s, CoincheRank r) =>
          CoincheCard(suit: s, rank: r, id: '${s.name}-${r.label}');
      expect(coincheCardAsset(c(CoincheSuit.epees, CoincheRank.valet)),
          'assets/images/cards_rami/jack_of_spades.webp');
      expect(coincheCardAsset(c(CoincheSuit.coupes, CoincheRank.dame)),
          'assets/images/cards_rami/queen_of_hearts.webp');
      expect(coincheCardAsset(c(CoincheSuit.deniers, CoincheRank.roi)),
          'assets/images/cards_rami/king_of_diamonds.webp');
      expect(coincheCardAsset(c(CoincheSuit.batons, CoincheRank.ace)),
          'assets/images/cards_rami/ace_of_clubs.webp');
      expect(coincheCardAsset(c(CoincheSuit.batons, CoincheRank.ten)),
          'assets/images/cards_rami/10_of_clubs.webp');
    });
  });
}

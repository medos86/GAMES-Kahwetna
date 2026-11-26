// Belote : mise en page du tapis, des sièges et de la distribution (issues #1001 à #1009).
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/coinche/coinche_layout.dart';
import 'package:kahwetne/game/coinche.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('le tapis est un dégradé radial rouge (#1001)', () {
    final gradient = coincheFeltGradient();
    expect(gradient, isA<RadialGradient>());
    expect(gradient.colors, hasLength(3));
    expect(gradient.colors.first, const Color(0xFFEF4444));
  });

  test('la barre du score du haut est retirée (#1002)', () {
    expect(coincheShowTopScoreBar, isFalse);
  });

  test('la marge du tapis est plus serrée qu\'avant (#1003)', () {
    expect(coincheTablePadding.left, lessThan(12));
    expect(coincheTablePadding.right, lessThan(12));
    expect(coincheTablePadding.top, lessThan(12));
  });

  test('chaque équipe a deux sièges face à face (#1004)', () {
    expect(coincheTeamSeats(Team.ns), [Seat.south, Seat.north]);
    expect(coincheTeamSeats(Team.ew), [Seat.west, Seat.east]);
  });

  test('le coin d\'annonce affiche « Enchères » sans contrat (#1005)', () {
    expect(coincheCornerTitle(null), 'Enchères');
    const contract = Contract(
      seat: Seat.north,
      value: 80,
      mode: CoincheSuit.coupes,
      multiplier: 1,
    );
    expect(coincheCornerTitle(contract), '80 ♥');
  });

  test(
    'les avatars sont plus grands qu\'avant, le joueur actif le plus (#1006)',
    () {
      expect(coincheAvatarSize(active: false), greaterThan(28));
      expect(coincheAvatarSize(active: true), greaterThan(40));
      expect(
        coincheAvatarSize(active: true),
        greaterThan(coincheAvatarSize(active: false)),
      );
    },
  );

  test('chaque joueur a sa couleur d\'anneau, toutes différentes (#1007)', () {
    final colors = Seat.values.map(coincheSeatRingColor).toSet();
    expect(colors, hasLength(4));
  });

  test('la main du joueur est plus grande qu\'avant (#1008)', () {
    expect(coincheHandScale, greaterThan(1.2));
  });

  test('la distribution est plus lente qu\'avant (#1009)', () {
    expect(coincheDealStep, greaterThan(const Duration(milliseconds: 90)));
  });
}

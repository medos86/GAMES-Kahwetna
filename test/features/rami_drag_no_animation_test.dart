import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_hand_layout.dart';

/// Issue #944 : un glisser-déposer (défausse ou tapis) ne lance pas de vol ;
/// la pose par bouton ou tap, elle, anime le départ de la carte.
void main() {
  test('glisser vers la défausse : aucun vol', () {
    expect(ramiShouldFlyLeaving(silentDrop: true, hasLeaving: true), isFalse);
  });

  test('glisser vers le tapis : aucun vol', () {
    expect(ramiShouldFlyLeaving(silentDrop: true, hasLeaving: true), isFalse);
  });

  test('défausser par bouton : le vol reste animé', () {
    expect(ramiShouldFlyLeaving(silentDrop: false, hasLeaving: true), isTrue);
  });

  test('rien ne quitte la main : pas de vol', () {
    expect(ramiShouldFlyLeaving(silentDrop: false, hasLeaving: false), isFalse);
  });
}

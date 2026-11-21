// Points du dé (#682) : une face hors 1 à 6 ne doit pas faire planter le rendu.
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/ludo/ludo_layout.dart';

void main() {
  test('#682 : faces 1 à 6 gardent leurs points', () {
    expect(ludoPipIndexes(1), [4]);
    expect(ludoPipIndexes(5), [0, 2, 4, 6, 8]);
    expect(ludoPipIndexes(6), hasLength(6));
  });

  test('#682 : face hors bornes ou absente : aucun point, sans exception', () {
    expect(ludoPipIndexes(0), isEmpty);
    expect(ludoPipIndexes(7), isEmpty);
    expect(ludoPipIndexes(-1), isEmpty);
    expect(ludoPipIndexes(null), isEmpty);
  });
}

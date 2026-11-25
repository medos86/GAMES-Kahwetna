import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';

void main() {
  test('une carte distribuée = un son', () {
    expect(dealSoundDelays(3), const [
      Duration.zero,
      Duration(milliseconds: 90),
      Duration(milliseconds: 180),
    ]);
  });

  test('aucune carte = aucun son', () {
    expect(dealSoundDelays(0), isEmpty);
    expect(dealSoundDelays(-2), isEmpty);
  });

  test('le nombre de sons est plafonné pour rester court', () {
    expect(dealSoundDelays(32).length, maxDealSounds);
    expect(dealSoundDelays(32).last, dealGap * (maxDealSounds - 1));
  });

  test('les sons sont espacés régulièrement et dans l ordre', () {
    final delays = dealSoundDelays(6);
    for (var i = 1; i < delays.length; i++) {
      expect(delays[i] - delays[i - 1], dealGap);
    }
  });
}

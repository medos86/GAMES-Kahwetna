import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';
import 'package:kahwetne/core/feedback/capture_feedback.dart';

// Retour de capture (#913) : une vibration simple, double vibration + son pour Chkobba / 7AYA.
void main() {
  late List<String> calls;

  setUp(() {
    calls = [];
    CaptureFeedback.vibrate = () async => calls.add('vibrate');
    CaptureFeedback.pulse = () async => calls.add('pulse');
    CaptureFeedback.wait = (_) async => calls.add('wait');
    CaptureFeedback.playSound = (sfx) async => calls.add('sound:${sfx.name}');
  });

  test('capture simple : une seule petite vibration, pas de son', () async {
    await CaptureFeedback.onCapture(special: false);

    expect(calls, ['vibrate']);
  });

  test('Chkobba ou 7AYA : double vibration puis petit son', () async {
    await CaptureFeedback.onCapture(special: true);

    expect(calls, ['pulse', 'wait', 'pulse', 'sound:${Sfx.capture.name}']);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/audio/sounds.dart';
import 'package:kahwetne/core/feedback/capture_feedback.dart';

// Retour de capture (#913) : une vibration simple, double vibration + son pour Chkobba / 7AYA.
void main() {
  testFailingHaptics();
  late List<String> calls;

  setUp(() {
    calls = [];
    CaptureFeedback.vibrate = () async => calls.add('vibrate');
    CaptureFeedback.pulse = () async => calls.add('pulse');
    CaptureFeedback.playSound = (sfx) async => calls.add('sound:${sfx.name}');
  });

  test('capture simple : une seule petite vibration, pas de son', () async {
    await CaptureFeedback.onCapture(special: false);

    expect(calls, ['vibrate']);
  });

  test('Chkobba ou 7AYA : double vibration puis petit son (sans minuteur)', () async {
    await CaptureFeedback.onCapture(special: true);

    expect(calls, ['vibrate', 'pulse', 'sound:${Sfx.capture.name}']);
  });
}

// Sans binding ni plateforme (tests unitaires), le retour ne doit jamais lever d'erreur.
void testFailingHaptics() {
  test('haptique indisponible : pas d\'erreur propagée', () async {
    CaptureFeedback.vibrate = () async => throw StateError('no binding');
    CaptureFeedback.pulse = () async => throw StateError('no binding');
    await CaptureFeedback.onCapture(special: true);
    await CaptureFeedback.onCapture(special: false);
  });
}

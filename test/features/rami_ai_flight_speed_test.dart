import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/features/rami/rami_controller.dart';
import 'package:kahwetne/widgets/card_motion.dart';

/// Issue #368 : un coup adverse doit voler assez longtemps pour être suivi.
void main() {
  test('le vol d un coup adverse dure au moins 400 ms', () {
    expect(ramiAiFlightDuration.inMilliseconds, greaterThanOrEqualTo(400));
  });

  test('le vol reste plus court que le délai entre deux coups adverses', () {
    expect(ramiAiFlightDuration, lessThan(ramiAiDelay));
  });

  test('un vol sans durée explicite garde 300 ms', () {
    const flight = CardFlight(
      from: Rect.zero,
      to: _noTarget,
      child: SizedBox(),
    );
    expect(flight.duration, const Duration(milliseconds: 300));
  });
}

Rect? _noTarget() => null;

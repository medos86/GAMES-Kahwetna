import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_events.dart';

void main() {
  test('chaque événement est émis une seule fois par pub', () {
    final records = <AdEventRecord>[];
    final tracker = AdEventTracker(sink: records.add);

    expect(tracker.track(AdEvent.impression, 'ad-1'), isTrue);
    expect(tracker.track(AdEvent.impression, 'ad-1'), isFalse);
    expect(tracker.track(AdEvent.impression, 'ad-2'), isTrue);
    expect(tracker.track(AdEvent.click, 'ad-1'), isTrue);

    expect(records.length, 3);
  });

  test('un identifiant vide est refusé', () {
    final records = <AdEventRecord>[];
    final tracker = AdEventTracker(sink: records.add);

    expect(tracker.track(AdEvent.impression, ''), isFalse);
    expect(records, isEmpty);
  });

  test('le payload ne contient aucune donnée personnelle', () {
    const record = AdEventRecord(
      event: AdEvent.revenue,
      adId: 'ad-7',
      value: 0.12,
    );
    final payload = record.toPayload();

    expect(payload.keys.toSet(), kAdEventPayloadKeys);
    expect(payload['event'], 'revenue');
    expect(payload['adId'], 'ad-7');
    expect(payload['value'], 0.12);
  });

  test('sans valeur, la clé value est absente du payload', () {
    const record = AdEventRecord(event: AdEvent.impression, adId: 'ad-3');
    final payload = record.toPayload();

    expect(payload.containsKey('value'), isFalse);
    expect(payload.keys.every(kAdEventPayloadKeys.contains), isTrue);
  });

  test('sans sink, le suivi ne plante pas', () {
    final tracker = AdEventTracker();
    expect(tracker.track(AdEvent.videoCompleted, 'ad-9'), isTrue);
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_consent.dart';
import 'package:kahwetne/core/services/consent_sync.dart';

class _MemoryStore implements AdConsentStore {
  _MemoryStore([this.value]);

  AdConsentState? value;

  @override
  Future<AdConsentState?> read() async => value;

  @override
  Future<void> write(AdConsentState state) async {
    value = state;
  }
}

class _FakeUmp implements UmpGateway {
  _FakeUmp({this.fail = false, this.canRequest = true});

  final bool fail;
  final bool canRequest;

  @override
  Future<void> requestUpdate() async {
    if (fail) throw StateError('ump');
  }

  @override
  Future<void> loadAndShowFormIfRequired() async {}

  @override
  Future<bool> canRequestAds() async => canRequest;
}

class _FakeTracking implements TrackingAuthorizer {
  _FakeTracking(this.allowed);

  final bool allowed;
  int asked = 0;

  @override
  Future<bool> requestAuthorization() async {
    asked++;
    return allowed;
  }
}

void main() {
  test('erreur UMP : état précédent conservé, ATT non demandé', () async {
    final store = _MemoryStore(AdConsentState.denied);
    final consent = ConsentService(store: store);
    final tracking = _FakeTracking(true);

    await syncConsent(
      consent: consent,
      ump: _FakeUmp(fail: true),
      tracking: tracking,
    );

    expect(consent.state.value, AdConsentState.denied);
    expect(tracking.asked, 0);
  });

  test('UMP ne permet pas les pubs : refus, ATT non demandé', () async {
    final consent = ConsentService(store: _MemoryStore());
    final tracking = _FakeTracking(true);

    await syncConsent(
      consent: consent,
      ump: _FakeUmp(canRequest: false),
      tracking: tracking,
    );

    expect(consent.state.value, AdConsentState.denied);
    expect(tracking.asked, 0);
  });

  test('UMP autorise et ATT accordé : pubs personnalisées', () async {
    final consent = ConsentService(store: _MemoryStore());

    await syncConsent(
      consent: consent,
      ump: _FakeUmp(),
      tracking: _FakeTracking(true),
    );

    expect(consent.canShowPersonalizedAds, isTrue);
  });

  test('UMP autorise mais ATT refusé : non personnalisées', () async {
    final consent = ConsentService(store: _MemoryStore());

    await syncConsent(
      consent: consent,
      ump: _FakeUmp(),
      tracking: _FakeTracking(false),
    );

    expect(consent.state.value, AdConsentState.denied);
  });

  test('hors iOS, le suivi est accordé sans question', () async {
    var asked = false;
    final authorizer = PlatformTrackingAuthorizer(
      isIos: () => false,
      ask: () async {
        asked = true;
        return false;
      },
    );

    expect(await authorizer.requestAuthorization(), isTrue);
    expect(asked, isFalse);
  });

  test('sur iOS, la réponse ATT est utilisée', () async {
    final authorizer = PlatformTrackingAuthorizer(
      isIos: () => true,
      ask: () async => false,
    );

    expect(await authorizer.requestAuthorization(), isFalse);
  });
}

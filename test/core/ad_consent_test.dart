import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_consent.dart';

/// Stockage en mémoire : aucune dépendance à SharedPreferences dans les tests.
class _MemoryConsentStore implements AdConsentStore {
  _MemoryConsentStore([this.value]);

  AdConsentState? value;

  @override
  Future<AdConsentState?> read() async => value;

  @override
  Future<void> write(AdConsentState state) async {
    value = state;
  }
}

void main() {
  test('sans choix enregistré, le consentement est non demandé', () async {
    final service = ConsentService(store: _MemoryConsentStore());
    await service.load();

    expect(service.state.value, AdConsentState.notRequested);
    expect(service.canShowPersonalizedAds, isFalse);
  });

  test('accorder le consentement autorise les pubs personnalisées', () async {
    final store = _MemoryConsentStore();
    final service = ConsentService(store: store);

    await service.grant();

    expect(service.state.value, AdConsentState.granted);
    expect(service.canShowPersonalizedAds, isTrue);
    expect(store.value, AdConsentState.granted);
  });

  test('refuser le consentement interdit les pubs personnalisées', () async {
    final store = _MemoryConsentStore();
    final service = ConsentService(store: store);

    await service.deny();

    expect(service.state.value, AdConsentState.denied);
    expect(service.canShowPersonalizedAds, isFalse);
    expect(store.value, AdConsentState.denied);
  });

  test('retirer le choix repasse en non demandé', () async {
    final store = _MemoryConsentStore(AdConsentState.granted);
    final service = ConsentService(store: store);
    await service.load();

    await service.withdraw();

    expect(service.state.value, AdConsentState.notRequested);
    expect(service.canShowPersonalizedAds, isFalse);
    expect(store.value, AdConsentState.notRequested);
  });

  test('le choix conservé est relu au démarrage', () async {
    final service = ConsentService(
      store: _MemoryConsentStore(AdConsentState.denied),
    );

    await service.load();

    expect(service.state.value, AdConsentState.denied);
  });
}

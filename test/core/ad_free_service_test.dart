import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/ad_free_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage en mémoire : se termine en microtâches, donc utilisable sous fakeAsync.
class _MemoryStore implements AdFreeStore {
  _MemoryStore([this.value]);

  int? value;
  int writes = 0;

  @override
  Future<int?> readExpiry() async => value;

  @override
  Future<void> writeExpiry(int epochMillis) async {
    value = epochMillis;
    writes++;
  }
}

final DateTime _start = DateTime(2026, 11, 10, 12);

void main() {
  test('même clé de stockage et même durée que le source', () {
    expect(AdFreeService.prefsKey, 'kahwetne-ad-free-until');
    expect(AdFreeService.duration, const Duration(minutes: 30));
  });

  test('inactif au départ', () {
    final service = AdFreeService(store: _MemoryStore());
    expect(service.active.value, isFalse);
    expect(service.remaining, Duration.zero);
    service.dispose();
  });

  test('activate : actif 30 minutes, puis expire tout seul', () {
    fakeAsync((async) {
      final store = _MemoryStore();
      final service = AdFreeService(
        store: store,
        now: () => _start.add(async.elapsed),
      );
      final events = <bool>[];
      service.active.addListener(() => events.add(service.active.value));

      service.activate();
      async.flushMicrotasks();
      expect(service.active.value, isTrue);
      expect(service.remaining, AdFreeService.duration);
      expect(
        store.value,
        _start.add(AdFreeService.duration).millisecondsSinceEpoch,
      );

      async.elapse(const Duration(minutes: 29, seconds: 59));
      expect(service.active.value, isTrue, reason: 'encore une seconde');
      expect(service.remaining, const Duration(seconds: 1));

      async.elapse(const Duration(seconds: 1));
      expect(service.active.value, isFalse, reason: 'expiration automatique');
      expect(service.remaining, Duration.zero);
      expect(events, [
        true,
        false,
      ], reason: 'une notification à l\'activation, une à l\'expiration');

      service.dispose();
    });
  });

  test('remaining diminue avec le temps', () {
    fakeAsync((async) {
      final service = AdFreeService(
        store: _MemoryStore(),
        now: () => _start.add(async.elapsed),
      );
      service.activate();
      async.flushMicrotasks();

      async.elapse(const Duration(minutes: 12, seconds: 30));
      expect(service.remaining, const Duration(minutes: 17, seconds: 30));
      service.dispose();
    });
  });

  test(
    'activer à nouveau repart pour 30 minutes pleines (sans double expiration)',
    () {
      fakeAsync((async) {
        final service = AdFreeService(
          store: _MemoryStore(),
          now: () => _start.add(async.elapsed),
        );
        final events = <bool>[];
        service.active.addListener(() => events.add(service.active.value));

        service.activate();
        async.flushMicrotasks();
        async.elapse(const Duration(minutes: 20));
        service.activate();
        async.flushMicrotasks();
        expect(service.remaining, AdFreeService.duration);

        // L'ancienne échéance (à 30 min) est passée sans effet.
        async.elapse(const Duration(minutes: 29, seconds: 59));
        expect(service.active.value, isTrue);
        async.elapse(const Duration(seconds: 1));
        expect(service.active.value, isFalse);
        expect(events, [true, false]);

        service.dispose();
      });
    },
  );

  test('load : une échéance déjà passée laisse le mode inactif', () {
    fakeAsync((async) {
      final store = _MemoryStore(
        _start.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
      );
      final service = AdFreeService(
        store: store,
        now: () => _start.add(async.elapsed),
      );

      service.load();
      async.flushMicrotasks();
      expect(service.active.value, isFalse);
      expect(service.remaining, Duration.zero);
      service.dispose();
    });
  });

  test('load : une échéance future active le mode et expire à l\'heure', () {
    fakeAsync((async) {
      final store = _MemoryStore(
        _start.add(const Duration(minutes: 10)).millisecondsSinceEpoch,
      );
      final service = AdFreeService(
        store: store,
        now: () => _start.add(async.elapsed),
      );

      service.load();
      async.flushMicrotasks();
      expect(service.active.value, isTrue);
      expect(service.remaining, const Duration(minutes: 10));

      async.elapse(const Duration(minutes: 10));
      expect(service.active.value, isFalse);
      service.dispose();
    });
  });

  test('load : rien de conservé laisse le mode inactif', () {
    fakeAsync((async) {
      final service = AdFreeService(
        store: _MemoryStore(),
        now: () => _start.add(async.elapsed),
      );
      service.load();
      async.flushMicrotasks();
      expect(service.active.value, isFalse);
      service.dispose();
    });
  });

  test(
    'persistance : un nouveau service (redémarrage simulé) retrouve le mode',
    () {
      fakeAsync((async) {
        final store = _MemoryStore();
        DateTime now() => _start.add(async.elapsed);

        final first = AdFreeService(store: store, now: now);
        first.activate();
        async.flushMicrotasks();
        first.dispose();

        async.elapse(const Duration(minutes: 5));

        final second = AdFreeService(store: store, now: now);
        expect(second.active.value, isFalse, reason: 'avant load()');
        second.load();
        async.flushMicrotasks();
        expect(second.active.value, isTrue);
        expect(second.remaining, const Duration(minutes: 25));

        async.elapse(const Duration(minutes: 25));
        expect(second.active.value, isFalse);
        second.dispose();
      });
    },
  );

  test('SharedPreferences : valeur écrite sous la bonne clé et relue après redémarrage', () async {
    SharedPreferences.setMockInitialValues({});
    var now = _start;

    final first = AdFreeService(now: () => now);
    await first.activate();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getInt('kahwetne-ad-free-until'),
      _start.add(AdFreeService.duration).millisecondsSinceEpoch,
    );
    first.dispose();

    now = _start.add(const Duration(minutes: 10));
    final second = AdFreeService(now: () => now);
    await second.load();
    expect(second.active.value, isTrue);
    expect(second.remaining, const Duration(minutes: 20));
    second.dispose();

    now = _start.add(const Duration(minutes: 31));
    final third = AdFreeService(now: () => now);
    await third.load();
    expect(
      third.active.value,
      isFalse,
      reason: 'redémarrage après l\'échéance',
    );
    third.dispose();
  });
}

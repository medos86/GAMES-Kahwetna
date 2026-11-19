import 'package:flutter_test/flutter_test.dart';
import 'package:kahwetne/core/services/age_gate_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stockage en mémoire : aucune dépendance à SharedPreferences ici.
class _MemoryAgeGateStore implements AgeGateStore {
  _MemoryAgeGateStore([this.value]);

  AgeGateRecord? value;

  @override
  Future<AgeGateRecord?> read() async => value;

  @override
  Future<void> write(AgeGateRecord record) async => value = record;

  @override
  Future<void> clear() async => value = null;
}

final DateTime _fixedNow = DateTime.utc(2026, 11, 19, 12);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AgeGateService', () {
    test('sans réponse : non répondu, question à poser', () async {
      final service = AgeGateService(store: _MemoryAgeGateStore());
      await service.load();

      expect(service.answers.value, AgeAnswer.unanswered);
      expect(service.record, isNull);
      expect(service.shouldAsk, isTrue);
    });

    test('setAnswer enregistre date et version du texte', () async {
      final store = _MemoryAgeGateStore();
      final service = AgeGateService(store: store, now: () => _fixedNow);
      await service.load();

      await service.setAnswer(AgeAnswer.thirteenOrOver);

      expect(service.answers.value, AgeAnswer.thirteenOrOver);
      expect(store.value?.answer, AgeAnswer.thirteenOrOver);
      expect(store.value?.answeredAt, _fixedNow);
      expect(store.value?.textVersion, kAgeGateTextVersion);
      expect(service.shouldAsk, isFalse);
    });

    test('la réponse survit à un redémarrage', () async {
      final store = _MemoryAgeGateStore();
      final first = AgeGateService(store: store, now: () => _fixedNow);
      await first.setAnswer(AgeAnswer.underThirteen);

      final afterRestart = AgeGateService(store: store);
      await afterRestart.load();

      expect(afterRestart.answers.value, AgeAnswer.underThirteen);
      expect(afterRestart.shouldAsk, isFalse);
    });

    test('setAnswer(unanswered) efface la réponse', () async {
      final store = _MemoryAgeGateStore();
      final service = AgeGateService(store: store);
      await service.load();
      await service.setAnswer(AgeAnswer.thirteenOrOver);

      await service.setAnswer(AgeAnswer.unanswered);

      expect(store.value, isNull);
      expect(service.answers.value, AgeAnswer.unanswered);
      expect(service.shouldAsk, isTrue);
    });

    test('reset efface la réponse et redemande la question', () async {
      final store = _MemoryAgeGateStore();
      final service = AgeGateService(store: store);
      await service.load();
      await service.setAnswer(AgeAnswer.thirteenOrOver);

      await service.reset();

      expect(store.value, isNull);
      expect(service.shouldAsk, isTrue);
    });

    test('un texte plus récent redemande la question', () async {
      final oldRecord = AgeGateRecord(
        answer: AgeAnswer.thirteenOrOver,
        answeredAt: _fixedNow,
        textVersion: kAgeGateTextVersion - 1,
      );
      final store = _MemoryAgeGateStore(oldRecord);
      final service = AgeGateService(store: store);
      await service.load();

      expect(service.shouldAsk, isTrue);
    });
  });

  group('AgeGateRecord.fromJson', () {
    test('relit un enregistrement valide', () {
      final record = AgeGateRecord.fromJson({
        'answer': 'thirteenOrOver',
        'answeredAt': _fixedNow.millisecondsSinceEpoch,
        'textVersion': 1,
      });

      expect(record?.answer, AgeAnswer.thirteenOrOver);
      expect(record?.answeredAt, _fixedNow);
      expect(record?.textVersion, 1);
    });

    test('rejette une réponse inconnue', () {
      final record = AgeGateRecord.fromJson({
        'answer': 'bogus',
        'answeredAt': 0,
        'textVersion': 1,
      });

      expect(record, isNull);
    });

    test('rejette « unanswered » stocké', () {
      final record = AgeGateRecord.fromJson({
        'answer': 'unanswered',
        'answeredAt': 0,
        'textVersion': 1,
      });

      expect(record, isNull);
    });

    test('rejette une date qui n’est pas un entier', () {
      final record = AgeGateRecord.fromJson({
        'answer': 'thirteenOrOver',
        'answeredAt': 'pas une date',
        'textVersion': 1,
      });

      expect(record, isNull);
    });

    test('rejette un contenu qui n’est pas une map', () {
      expect(AgeGateRecord.fromJson('texte'), isNull);
    });
  });

  group('SharedPreferencesAgeGateStore', () {
    test('une valeur illisible est traitée comme absente', () async {
      SharedPreferences.setMockInitialValues({
        AgeGateService.prefsKey: 'pas du json {',
      });
      final service = AgeGateService();
      await service.load();

      expect(service.answers.value, AgeAnswer.unanswered);
      expect(service.shouldAsk, isTrue);
    });

    test('écrit puis relit la réponse', () async {
      SharedPreferences.setMockInitialValues({});
      final service = AgeGateService(now: () => _fixedNow);
      await service.load();
      await service.setAnswer(AgeAnswer.thirteenOrOver);

      final reloaded = AgeGateService();
      await reloaded.load();

      expect(reloaded.answers.value, AgeAnswer.thirteenOrOver);
    });
  });
}

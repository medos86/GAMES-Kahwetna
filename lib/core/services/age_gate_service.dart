import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Réponse du joueur à la question d'âge (issue #566, décision #565).
///
/// - [unanswered] : pas de réponse. Traité comme âge inconnu.
/// - [thirteenOrOver] : « oui, 13 ans ou plus ».
/// - [underThirteen] : « non, moins de 13 ans ».
enum AgeAnswer { unanswered, thirteenOrOver, underThirteen }

/// Version du texte de la question. À incrémenter si la formulation change,
/// pour savoir quel texte le joueur a réellement vu.
const int kAgeGateTextVersion = 1;

/// Réponse conservée, avec la date et la version du texte affiché.
class AgeGateRecord {
  const AgeGateRecord({
    required this.answer,
    required this.answeredAt,
    required this.textVersion,
  });

  final AgeAnswer answer;
  final DateTime answeredAt;
  final int textVersion;

  Map<String, Object> toJson() => {
        'answer': answer.name,
        'answeredAt': answeredAt.millisecondsSinceEpoch,
        'textVersion': textVersion,
      };

  /// Renvoie `null` si la valeur conservée est absente ou illisible.
  static AgeGateRecord? fromJson(Object? decoded) {
    if (decoded is! Map) return null;
    final name = decoded['answer'];
    final millis = decoded['answeredAt'];
    final version = decoded['textVersion'];
    if (name is! String || millis is! int || version is! int) return null;
    for (final answer in AgeAnswer.values) {
      if (answer.name == name && answer != AgeAnswer.unanswered) {
        return AgeGateRecord(
          answer: answer,
          answeredAt: DateTime.fromMillisecondsSinceEpoch(millis, isUtc: true),
          textVersion: version,
        );
      }
    }
    return null;
  }
}

/// Où la réponse d'âge est conservée.
abstract interface class AgeGateStore {
  Future<AgeGateRecord?> read();

  Future<void> write(AgeGateRecord record);

  Future<void> clear();
}

/// Stockage réel : `SharedPreferences`, même mécanisme que le consentement.
class SharedPreferencesAgeGateStore implements AgeGateStore {
  const SharedPreferencesAgeGateStore();

  @override
  Future<AgeGateRecord?> read() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(AgeGateService.prefsKey);
    if (raw == null) return null;
    try {
      return AgeGateRecord.fromJson(jsonDecode(raw));
    } on FormatException {
      return null;
    }
  }

  @override
  Future<void> write(AgeGateRecord record) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      AgeGateService.prefsKey,
      jsonEncode(record.toJson()),
    );
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AgeGateService.prefsKey);
  }
}

/// Réponse à la question d'âge (issue #566).
///
/// - [load] relit la réponse conservée, à appeler une fois au démarrage.
/// - [setAnswer] enregistre une réponse avec la date et la version du texte.
/// - [shouldAsk] dit s'il faut poser la question (jamais répondue, ou texte
///   changé depuis la réponse).
class AgeGateService {
  AgeGateService({AgeGateStore? store, DateTime Function()? now})
      : _store = store ?? const SharedPreferencesAgeGateStore(),
        _now = now ?? DateTime.now;

  /// Instance partagée par toute l'application.
  static final AgeGateService instance = AgeGateService();

  /// Clé de conservation de la réponse.
  static const String prefsKey = 'kahwetne-age-gate';

  final AgeGateStore _store;
  final DateTime Function() _now;
  final ValueNotifier<AgeAnswer> _answer =
      ValueNotifier<AgeAnswer>(AgeAnswer.unanswered);
  AgeGateRecord? _record;

  /// Réponse courante, observable par l'interface.
  ValueListenable<AgeAnswer> get answers => _answer;

  /// Dernier enregistrement connu (`null` si jamais répondu).
  AgeGateRecord? get record => _record;

  /// `true` si la question doit être posée (jamais répondue, ou texte changé).
  bool get shouldAsk {
    final current = _record;
    return current == null || current.textVersion < kAgeGateTextVersion;
  }

  /// Relit la réponse conservée. Une valeur illisible compte comme absente.
  Future<void> load() async {
    final stored = await _store.read();
    _record = stored;
    _answer.value = stored?.answer ?? AgeAnswer.unanswered;
  }

  /// Enregistre une réponse. [AgeAnswer.unanswered] efface la réponse.
  Future<void> setAnswer(AgeAnswer answer) async {
    if (answer == AgeAnswer.unanswered) {
      await reset();
      return;
    }
    final next = AgeGateRecord(
      answer: answer,
      answeredAt: _now(),
      textVersion: kAgeGateTextVersion,
    );
    await _store.write(next);
    _record = next;
    _answer.value = answer;
  }

  /// Efface la réponse (le joueur pourra la donner à nouveau).
  Future<void> reset() async {
    await _store.clear();
    _record = null;
    _answer.value = AgeAnswer.unanswered;
  }
}

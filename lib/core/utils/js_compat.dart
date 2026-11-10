/// Équivalents Dart de comportements JavaScript du source React.
///
/// Guide §4.2 et §4.1 (pièges 1 et 2). Ne dépend de rien d'autre que `dart:core` :
/// utilisable depuis `lib/game/` sans tirer Flutter.
library;

/// Équivalent de `Array.prototype.slice(start, end)`.
///
/// - Les indices négatifs comptent depuis la fin.
/// - Les bornes hors liste sont ramenées dans `[0, length]` (aucune exception).
/// - `end` omis signifie « jusqu'à la fin ».
/// - Si `start >= end` après normalisation, le résultat est une liste vide.
List<T> slice<T>(List<T> items, [int start = 0, int? end]) {
  final length = items.length;
  final from = _normalizeIndex(start, length);
  final to = end == null ? length : _normalizeIndex(end, length);
  if (from >= to) return <T>[];
  return items.sublist(from, to);
}

int _normalizeIndex(int index, int length) {
  if (index < 0) {
    final shifted = length + index;
    return shifted < 0 ? 0 : shifted;
  }
  return index > length ? length : index;
}

/// Tri stable : à comparaison égale, l'ordre d'origine est conservé.
///
/// `List.sort` de Dart n'est pas garanti stable, alors que
/// `Array.prototype.sort` l'est (ES2019). La liste d'origine n'est pas modifiée.
List<T> sortedStable<T>(List<T> items, int Function(T a, T b) compare) {
  final indexed = <({int index, T item})>[
    for (var i = 0; i < items.length; i++) (index: i, item: items[i]),
  ];
  indexed.sort((x, y) {
    final c = compare(x.item, y.item);
    return c != 0 ? c : x.index.compareTo(y.index);
  });
  return <T>[for (final entry in indexed) entry.item];
}

/// Mélange de Fisher-Yates identique au source : parcours de la fin vers le
/// début, `j = floor(random() * (i + 1))`, échange des positions `i` et `j`.
///
/// `random` renvoie un double dans `[0, 1)` (comme `Math.random`). Avec une
/// suite de valeurs fixée, le résultat est donc identique à celui du source,
/// ce qui permet les tests de parité. La liste d'origine n'est pas modifiée.
List<T> shuffled<T>(List<T> items, double Function() random) {
  final copy = <T>[...items];
  for (var i = copy.length - 1; i > 0; i--) {
    final j = (random() * (i + 1)).floor();
    final tmp = copy[i];
    copy[i] = copy[j];
    copy[j] = tmp;
  }
  return copy;
}

// Dart pur : aucun import Flutter dans lib/game/.

/// Joueur humain et adversaire (partagé par Chkobba et Domino).
enum Player { player, opponent }

Player other(Player p) => p == Player.player ? Player.opponent : Player.player;

/// Joueur depuis sa valeur JSON (`'player'` ou `'opponent'`), ou null si la valeur est absente.
Player? playerFromJson(Object? value) =>
    value == null ? null : Player.values.byName(value as String);

/// Entier depuis une valeur JSON (accepte aussi un nombre à virgule entier, comme `1.0`).
int intFromJson(Object? value) => (value as num).toInt();

/// Tirage d'un double dans [0, 1[ : même rôle que Math.random() dans le source.
typedef RandomDouble = double Function();

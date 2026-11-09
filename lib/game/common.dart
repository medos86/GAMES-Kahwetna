// Dart pur : aucun import Flutter dans lib/game/.

/// Joueur humain et adversaire (partagé par Chkobba et Domino).
enum Player { player, opponent }

Player other(Player p) => p == Player.player ? Player.opponent : Player.player;

/// Tirage d'un double dans [0, 1[ : même rôle que Math.random() dans le source.
typedef RandomDouble = double Function();

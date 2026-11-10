// Libellés de l'interface (guide §0.1 règle 6 : textes identiques au source, centralisés).
// Les constantes restent utilisables dans les widgets const.
// Les textes avec interpolation (« Manche 3 », scores…) restent dans leur écran : un suivi les reprendra.

/// Libellés français (langue actuelle de l'application).
abstract final class Strings {
  static const menuScoreSection = 'Score de la partie';
  static const menuHumanPlayers = 'Joueurs humains';
  static const menuAiSeatsNote = 'Les autres places sont jouées par l’IA';
  static const menuBackToGames = 'Retour aux jeux';
  static const menuBack = 'Retour';
  static const menuToggleSound = 'Activer ou désactiver le son';
  static const menuOpenSettings = 'Ouvrir les paramètres';
  static const menuCoinBalance = 'Solde de pièces';
  static const menuTagline = 'EL KAHWA TEJMAÂNA';
  static const menuChooseTable = 'CHOISIS TA TABLE';
  static const menuStart = 'Commencer à jouer';
  static const menuAdFreeEnable = 'Activer 30 minutes sans publicité';
  static const menuAdFreeActive = 'Mode sans pub actif';
  static const menuAdFreeOffer = '30 min sans pub';
  static const menuAdFreeActiveNote = 'La partie reste 100% tranquille';
  static const menuAdFreeOfferNote = 'Une pause café, zéro interruption';
  static const menuChooseLevel = 'Choisis ton niveau';
  static const menuChooseLevelNote = 'Choisis ton ambiance de jeu et le score à atteindre.';
  static const menuLaunch = 'Lancer la partie';
  static const levelEasy = 'Facile';
  static const levelEasyDetail = 'Chill';
  static const levelMedium = 'Moyen';
  static const levelMediumDetail = 'Épicé';
  static const levelHard = 'Difficile';
  static const levelHardDetail = 'Expert';
  static const splashTap = 'Touchez pour commencer';
  static const adLabel = 'PUBLICITÉ';
  static const adTitle = 'Votre annonce dans Kahwetne';
  static const adSponsored = 'Partenaire local · contenu sponsorisé';
  static const adSeeSemantic = 'Voir la publicité';
  static const adSee = 'Voir';
  static const adDemoToast = 'Espace publicitaire de démonstration';
  static const suitCarreau = 'Carreau';
  static const suitCoeur = 'Cœur';
  static const suitPique = 'Pique';
  static const suitTrefle = 'Trèfle';
  static const victory = 'Victoire !';
  static const defeat = 'Défaite';
  static const menuLabel = 'Menu';
  static const close = 'Fermer';
  static const replay = 'Rejouer';
  static const backToMenu = 'Retour au menu';
  static const nextRoundButton = 'Manche suivante';
  static const matchOver = 'PARTIE TERMINÉE';
  static const actCancel = 'Annuler';
  static const roundWon = 'Manche gagnée !';
  static const drawExhausted = 'Pioche épuisée';
  static const seeRules = 'Voir les règles';
  static const headerRami = 'KAHWETNE · RAMI';
  static const rulesTitleRami = 'Règles du Rami';
  static const ramiYourDraw = 'À toi : touche la pioche ou la défausse';
  static const ramiSlideThenDiscard = 'Glisse un paquet sur la table, puis une carte sur la défausse';
  static const ramiDropHint = 'Glisse un paquet ici pour le poser';
  static const ramiNoMeld = 'Aucune combinaison posée';
  static const sortSuit = 'Couleur';
  static const sortRank = 'Valeur';
  static const selectionNotMeld = 'Sélection : pas une combinaison';
  static const ramiFormHint = 'Glisse tes cartes pour former des paquets';
  static const actPose = 'Poser';
  static const actDiscard = 'Défausser';
  static const jokerLabel = 'Joker';
  static const ramiFinishOpeningFirst = 'Valide ton ouverture d\'abord';
  static const ramiCannotLayOff = 'Cette carte ne peut pas être ajoutée ici';
  static const ramiSelectCardThenMeld = 'Sélectionne une carte, puis la combinaison';
  static const ramiSelectDiscard = 'Sélectionne la carte à défausser';
  static const ramiCannotDiscardTaken = 'Tu ne peux pas défausser la carte prise à la défausse';
  static const ramiDiscardRefused = 'Défausse impossible';
  static const ramiFinishOrCancel = 'Valide ou annule ton ouverture d\'abord';
  static const notAMeld = 'Ce n\'est pas une combinaison valide';
  static const drawFirst = 'Pioche d\'abord';
  static const waitTurn = 'Attends ton tour';
  static const ramiFormFirst = 'Forme d\'abord un paquet : 3 cartes ou plus côte à côte';
  static const rulesTitleChkobba = 'Règles de la Chkobba';
  static const backToMenuChkobba = 'Retour au Menu';
  // Domino (issue #30, source DominoGameScreen.tsx).
  static const dominoMatchOver = 'Partie terminée';
  static const dominoDrawUnavailable = 'Pioche indisponible';
  static const dominoPlaceHere = 'Poser ici';

  // Menu (issue #31, source MainMenu.tsx).
  static const menuAdFreeToastTitle = 'Mode tranquille activé';
  static const menuAdFreeToastBody = 'Profite de Kahwetne sans publicité pendant 30 minutes.';
  static const menuDifficultyTitle = 'Niveau de difficulté';
  static const menuHumanPlayersCount = 'Nombre de joueurs humains';
  static const menuComingSoonBody = 'On prépare la table. Encore un petit café ☕';
  static const menuBackgroundAlt = 'Ruelle tunisienne colorée aux portes bleues et bougainvilliers';

}

/// Équivalents arabes (noms de jeux et slogan, fournis par l'issue #10).
/// Les autres libellés n'ont pas encore de traduction : à relire par une personne arabophone.
abstract final class StringsAr {
  static const gameChkobba = 'شكبة';
  static const gameDomino = 'دومينو';
  static const gameLudo = 'لودو';
  static const gameRami = 'رامي';
  static const tagline = 'لمّـة، ضحكة ولعبة تونسية';
}

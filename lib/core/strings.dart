import '../i18n/app_language.dart';

// Libellés de l'interface (guide §0.1 règle 6 : textes identiques au source, centralisés).
// Les textes sont des getters : ils ne sont plus utilisables dans les widgets const (issue #100).
// Les textes avec interpolation (« Manche 3 », scores…) restent dans leur écran : un suivi les reprendra.

/// Libellés français (langue actuelle de l'application).

/// Libellés de l'interface, dans la langue courante (issue #100).
/// Les textes sont dans lib/core/i18n/translations.dart.
abstract final class Strings {
  static String get menuScoreSection => t('menuScoreSection');
  static String get menuHumanPlayers => t('menuHumanPlayers');
  static String get menuAiSeatsNote => t('menuAiSeatsNote');
  static String get menuBackToGames => t('menuBackToGames');
  static String get menuBack => t('menuBack');
  static String get menuToggleSound => t('menuToggleSound');
  static String get menuOpenSettings => t('menuOpenSettings');
  static String get menuCoinBalance => t('menuCoinBalance');
  static String get menuTagline => t('menuTagline');
  static String get menuChooseTable => t('menuChooseTable');
  static String get menuStart => t('menuStart');
  static String get menuAdFreeEnable => t('menuAdFreeEnable');
  static String get menuAdFreeActive => t('menuAdFreeActive');
  static String get menuAdFreeOffer => t('menuAdFreeOffer');
  static String get menuAdFreeActiveNote => t('menuAdFreeActiveNote');
  static String get menuAdFreeOfferNote => t('menuAdFreeOfferNote');
  static String get menuChooseLevel => t('menuChooseLevel');
  static String get menuChooseLevelNote => t('menuChooseLevelNote');
  static String get menuLaunch => t('menuLaunch');
  static String get levelEasy => t('levelEasy');
  static String get levelEasyDetail => t('levelEasyDetail');
  static String get levelMedium => t('levelMedium');
  static String get levelMediumDetail => t('levelMediumDetail');
  static String get levelHard => t('levelHard');
  static String get levelHardDetail => t('levelHardDetail');
  static String get splashTap => t('splashTap');
  static String get adLabel => t('adLabel');
  static String get adTitle => t('adTitle');
  static String get adSponsored => t('adSponsored');
  static String get adSeeSemantic => t('adSeeSemantic');
  static String get adSee => t('adSee');
  static String get adDemoToast => t('adDemoToast');
  static String get suitCarreau => t('suitCarreau');
  static String get suitCoeur => t('suitCoeur');
  static String get suitPique => t('suitPique');
  static String get suitTrefle => t('suitTrefle');
  static String get victory => t('victory');
  static String get defeat => t('defeat');
  static String get menuLabel => t('menuLabel');
  static String get close => t('close');
  static String get replay => t('replay');
  static String get backToMenu => t('backToMenu');
  static String get nextRoundButton => t('nextRoundButton');
  static String get matchOver => t('matchOver');
  static String get actCancel => t('actCancel');
  static String get roundWon => t('roundWon');
  static String get drawExhausted => t('drawExhausted');
  static String get seeRules => t('seeRules');
  static String get headerRami => t('headerRami');
  static String get rulesTitleRami => t('rulesTitleRami');
  static String get ramiYourDraw => t('ramiYourDraw');
  static String get ramiSlideThenDiscard => t('ramiSlideThenDiscard');
  static String get ramiDropHint => t('ramiDropHint');
  static String get ramiNoMeld => t('ramiNoMeld');
  static String get sortSuit => t('sortSuit');
  static String get sortRank => t('sortRank');
  static String get selectionNotMeld => t('selectionNotMeld');
  static String get ramiFormHint => t('ramiFormHint');
  static String get actPose => t('actPose');
  static String get actDiscard => t('actDiscard');
  static String get jokerLabel => t('jokerLabel');
  static String get ramiFinishOpeningFirst => t('ramiFinishOpeningFirst');
  static String get ramiCannotLayOff => t('ramiCannotLayOff');
  static String get ramiSelectCardThenMeld => t('ramiSelectCardThenMeld');
  static String get ramiSelectDiscard => t('ramiSelectDiscard');
  static String get ramiCannotDiscardTaken => t('ramiCannotDiscardTaken');
  static String get ramiDiscardRefused => t('ramiDiscardRefused');
  static String get ramiFinishOrCancel => t('ramiFinishOrCancel');
  static String get notAMeld => t('notAMeld');
  static String get drawFirst => t('drawFirst');
  static String get waitTurn => t('waitTurn');
  static String get ramiFormFirst => t('ramiFormFirst');
  static String get rulesTitleChkobba => t('rulesTitleChkobba');
  static String get backToMenuChkobba => t('backToMenuChkobba');
  static String get dominoMatchOver => t('dominoMatchOver');
  static String get dominoDrawUnavailable => t('dominoDrawUnavailable');
  static String get dominoPlaceHere => t('dominoPlaceHere');
  static String get menuAdFreeToastTitle => t('menuAdFreeToastTitle');
  static String get menuAdFreeToastBody => t('menuAdFreeToastBody');
  static String get menuDifficultyTitle => t('menuDifficultyTitle');
  static String get menuHumanPlayersCount => t('menuHumanPlayersCount');
  static String get menuComingSoonBody => t('menuComingSoonBody');
  static String get menuBackgroundAlt => t('menuBackgroundAlt');
  static String get chkobbaRuleHaya => t('chkobbaRuleHaya');
}

/// Noms de jeux et slogan (issue #10), dans la langue courante.
abstract final class StringsAr {
  static String get gameChkobba => t('gameChkobba');
  static String get gameDomino => t('gameDomino');
  static String get gameLudo => t('gameLudo');
  static String get gameRami => t('gameRami');
  static String get tagline => t('tagline');
}

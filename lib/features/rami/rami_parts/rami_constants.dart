part of '../rami_screen.dart';

/// Facteur d'agrandissement des cartes Rami (lisibilité sur téléphone), défini dans rami_hand_layout.dart (#314).
const double _ramiCardScale = ramiHandCardScale;

/// Clé partagée avec le mode sans pub (même nom que le web).
const _feltColor = Color(0xFF10B981);
const _frameColor = Color(0xFF4A2A10);
const _creamColor = Color(0xFFFFF8E7);
const _inkColor = Color(0xFF20284B);
const _goldColor = Color(0xFFFFE16B);
const _woodColor = Color(0xFF8B4513);
const _dragThreshold = 8.0;

const _seatNames = ['Toi', 'Ali', 'Karim', 'Sami'];

/// Couleur de chaque siège : bordure du paquet et étiquette du joueur qui l'a posé (#537).
const _seatColors = [
  Color(0xFF60A5FA), // Toi : bleu
  Color(0xFFF87171), // Ali : rouge
  Color(0xFFA3E635), // Karim : vert
  Color(0xFFC084FC), // Sami : violet
];

/// Nom du joueur qui a posé un paquet, ou null si le siège est inconnu (#537).
String? ramiOwnerName(int owner) =>
    owner >= 0 && owner < _seatNames.length ? _seatNames[owner] : null;

final _ramiRules = <({String title, String text})>[
  (
    title: 'Le jeu',
    text:
        '4 joueurs chacun pour soi : toi contre 3 IA. 2 jeux de 52 cartes + 2 jokers, 13 cartes chacun.',
  ),
  (
    title: 'Combinaisons',
    text: 'Suite : 3 cartes ou plus de même couleur qui se suivent (As bas ou haut, sans boucler). '
        'Brelan ou carré : 3 ou 4 cartes de même valeur et de couleurs différentes.',
  ),
  (
    title: Strings.jokerLabel,
    text:
        "Remplace n'importe quelle carte dans une combinaison, avec au moins 2 vraies cartes.",
  ),
  (
    title: 'Ouverture',
    text:
        'Ta première pose doit totaliser ${rules.ramiOpenMin} points minimum, en une seule fois. '
            'Chaque ouverture suivante doit dépasser la précédente. '
            'As = 1, figures = 10, joker = 20.',
  ),
  (
    title: 'Ton tour',
    text: 'Pioche dans la pioche ou prends la défausse. Pose tes combinaisons, ajoute des cartes sur '
        'celles de la table (une fois ouvert), puis défausse. La carte prise à la défausse ne peut pas '
        'être défaussée tout de suite.',
  ),
  (
    title: 'Glisser-déposer',
    text: 'Fais glisser tes cartes pour les ranger : une barre colorée sous des cartes voisines indique '
        'un paquet valide. Glisse un paquet sur la table pour le poser, une carte sur une combinaison '
        'pour l\'ajouter, ou sur la défausse pour finir ton tour. Un simple appui sélectionne une carte.',
  ),
  (
    title: 'Fin de manche',
    text:
        'Le premier qui vide sa main gagne la manche. Les autres comptent les points des cartes qui '
            'leur restent.',
  ),
  (
    title: 'Partie',
    text:
        "Les points de pénalité s'additionnent jusqu'à 100 ou 200. Le plus petit total gagne.",
  ),
];

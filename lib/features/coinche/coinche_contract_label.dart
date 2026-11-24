// Libellé de l'annonce en cours de la Belote (issue #774).
import '../../game/coinche.dart';
import 'coinche_card_view.dart';
import 'coinche_opponent_names.dart';

/// Libellé de l'annonce en cours, avec le joueur qui l'a faite (#774).
String coincheBidderContractLabel(
  Contract? contract,
  Map<Seat, String> seatNames,
) {
  if (contract == null) return 'Aucune annonce';
  final bidder = seatNames.containsKey(contract.seat)
      ? coincheSeatName(seatNames, contract.seat)
      : (contract.seat == Seat.south ? 'Toi' : contract.seat.name);
  final suit = coincheSuitSymbol(contract.mode);
  return 'Actuel : ${contract.value} $suit · $bidder';
}

/// Détail de l'annonce affiché sous le contrat du score (#839) : couleur d'atout, contre éventuel
/// et annonceur. Le pseudo du joueur remplace « Toi » pour le siège sud.
String coincheAnnounceDetail(
  Contract contract,
  Map<Seat, String> seatNames,
  String me,
) {
  final parts = [
    'Atout ${coincheSuitName(contract.mode)}',
    if (contract.multiplier >= 4) 'surcontré',
    if (contract.multiplier == 2) 'contré',
    'annoncé par ${coincheSeatName(seatNames, contract.seat, me)}',
  ];
  return parts.join(' · ');
}

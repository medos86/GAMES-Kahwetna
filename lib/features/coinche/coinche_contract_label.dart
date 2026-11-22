// Libellé de l'annonce en cours de la Belote (issue #780).
import '../../game/coinche.dart';
import 'coinche_card_view.dart';
import 'coinche_opponent_names.dart';

/// Libellé de l'annonce en cours, avec le joueur qui l'a faite (#780).
String coincheContractLabel(Contract? contract, Map<Seat, String> seatNames) {
  if (contract == null) return 'Aucune annonce';
  final bidder = seatNames.containsKey(contract.seat)
      ? coincheSeatName(seatNames, contract.seat)
      : (contract.seat == Seat.south ? 'Toi' : contract.seat.name);
  return 'Actuel : ${contract.value} ${coincheSuitSymbol(contract.mode)} · $bidder';
}

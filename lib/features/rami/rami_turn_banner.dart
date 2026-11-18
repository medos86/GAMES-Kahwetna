import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';
import '../../core/i18n/app_language.dart';
import '../../widgets/pulse_glow.dart';

const _turnFrame = Color(0xFF4A2A10);
const _turnCream = Color(0xFFFFF8E7);
const _turnInk = Color(0xFF20284B);
const _turnGold = Color(0xFFFFE16B);

/// Bannière de tour au-dessus de la main : or et pulsante quand c'est au joueur,
/// crème et discrète quand c'est à un adversaire (#524).
class RamiTurnBanner extends StatelessWidget {
  const RamiTurnBanner({
    super.key,
    required this.myTurn,
    required this.otherName,
  });

  final bool myTurn;
  final String otherName;

  @override
  Widget build(BuildContext context) {
    final label = myTurn
        ? Strings.ramiYourTurn
        : tf('ramiOtherTurn', {'n': otherName});
    return Semantics(
      liveRegion: true,
      label: label,
      child: PulseGlow(
        active: myTurn,
        radius: 20,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            color: myTurn ? _turnGold : _turnCream,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _turnFrame, width: 2),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: myTurn ? _turnInk : _turnInk.withValues(alpha: 0.7),
              fontSize: myTurn ? 15 : 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

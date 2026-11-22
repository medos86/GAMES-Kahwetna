part of '../coinche_screen.dart';

class _BidPanel extends StatelessWidget {
  const _BidPanel({required this.controller, this.seatNames = const {}});

  final CoincheController controller;
  final Map<Seat, String> seatNames;

  @override
  Widget build(BuildContext context) {
    final contract = controller.round.contract;
    final choiceValue = controller.choiceValue;
    final choiceMode = controller.choiceMode;
    final canAnnounce = choiceMode != null &&
        choiceValue != null &&
        choiceValue >= controller.minValue;

    return Container(
      constraints: const BoxConstraints(maxWidth: 420),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _creamColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _frameColor, width: 3),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t('yourBid'),
                  style: TextStyle(
                    color: _inkColor,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                coincheBidderContractLabel(contract, seatNames),
                style: const TextStyle(
                  color: _inkColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (final suit in _suitNames)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: _ChoiceButton(
                      label: coincheSuitSymbol(suit),
                      semanticsLabel: coincheSuitName(suit),
                      selected: choiceMode == suit,
                      textColor: coincheSuitColor(suit),
                      onTap: () => controller.setChoiceMode(suit),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          GridView.count(
            crossAxisCount: 5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.6,
            children: [
              for (var value = minBid; value <= maxBid; value += 10)
                _ChoiceButton(
                  label: '$value',
                  selected: choiceValue == value,
                  enabled: value >= controller.minValue,
                  textColor: _inkColor,
                  onTap: () => controller.setChoiceValue(value),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _ActionButton(
                label: t('pass'),
                onTap: () => controller.callBid(const PassBid()),
              ),
              _ActionButton(
                label: t('bid'),
                primary: true,
                enabled: canAnnounce,
                onTap: controller.announce,
              ),
              if (controller.canContre)
                _ActionButton(
                  label: t('contre'),
                  danger: true,
                  onTap: () => controller.callBid(const ContreBid()),
                ),
              if (controller.canSurcoinche)
                _ActionButton(
                  label: t('surcoinche'),
                  danger: true,
                  onTap: () => controller.callBid(const SurcoincheBid()),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ChoiceButton extends StatelessWidget {
  const _ChoiceButton({
    required this.label,
    required this.selected,
    required this.textColor,
    required this.onTap,
    this.semanticsLabel,
    this.enabled = true,
  });

  final String label;
  final String? semanticsLabel;
  final bool selected;
  final bool enabled;
  final Color textColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (kComicCoinche) {
      // Case BD (#156) : papier, jaune quand sélectionnée, libellé en Bangers.
      return Semantics(
        button: true,
        selected: selected,
        enabled: enabled,
        label: semanticsLabel,
        child: Opacity(
          opacity: enabled ? 1 : 0.3,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: ComicPanel(
              color: selected ? ComicPalette.yellow : ComicPalette.paper,
              radius: 10,
              shadowOffset: const Offset(2, 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Bangers',
                    fontSize: 20,
                    letterSpacing: 1,
                    color: ComicPalette.ink,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Semantics(
      button: true,
      selected: selected,
      label: semanticsLabel,
      child: Opacity(
        opacity: enabled ? 1 : 0.3,
        child: Material(
          color: selected ? _goldColor : Colors.white,
          borderRadius: BorderRadius.circular(10),
          child: InkWell(
            borderRadius: BorderRadius.circular(10),
            onTap: enabled ? onTap : null,
            child: Container(
              alignment: Alignment.center,
              constraints: const BoxConstraints(minHeight: 44),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: selected ? _frameColor : const Color(0x33152646),
                  width: 2,
                ),
              ),
              child: Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.onTap,
    this.primary = false,
    this.danger = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (kComicCoinche) {
      // Bouton BD (#146) : case papier, rouge pour le danger, jaune pour l'action principale.
      final fill = danger
          ? ComicPalette.red
          : (primary ? ComicPalette.yellow : ComicPalette.paper);
      final ink = danger ? ComicPalette.paper : ComicPalette.ink;
      return Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Semantics(
          button: true,
          enabled: enabled,
          label: label,
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: ComicPanel(
              color: fill,
              radius: 12,
              shadowOffset: const Offset(3, 3),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 24, minWidth: 86),
                child: Center(
                  child: Text(
                    label,
                    style: TextStyle(
                      fontFamily: 'Bangers',
                      fontSize: 18,
                      letterSpacing: 1,
                      color: ink,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    final Color background = danger
        ? const Color(0xFFD71920)
        : primary
            ? const Color(0xFFF2B74E)
            : Colors.white;
    final Color foreground = danger ? Colors.white : _inkColor;
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: enabled ? onTap : null,
          child: Container(
            constraints: const BoxConstraints(minHeight: 44, minWidth: 110),
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              label,
              style: TextStyle(color: foreground, fontWeight: FontWeight.w900),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Main du joueur
// ---------------------------------------------------------------------------


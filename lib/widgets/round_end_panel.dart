import 'package:material_ui/material_ui.dart';

import 'dialog_button.dart';

/// Une ligne du tableau de fin de manche : nom, variation, total, motif (#295).
class RoundEndRow {
  const RoundEndRow({
    required this.name,
    required this.delta,
    required this.total,
    this.reason,
    this.highlight = false,
  });

  final String name;
  final int delta;
  final int total;
  final String? reason;
  final bool highlight;
}

/// Écran de fin de manche / de partie, style BD, commun à tous les jeux (#295).
/// Le titre est en Bangers, la variation est signée, chaque ligne donne le motif.
class RoundEndPanel extends StatelessWidget {
  const RoundEndPanel({
    super.key,
    required this.badge,
    required this.title,
    required this.rows,
    required this.primaryLabel,
    required this.onPrimary,
    this.secondaryLabel,
    this.onSecondary,
    this.background = const Color(0xFF059669),
    this.accent = const Color(0xFFF4D28A),
  });

  final String badge;
  final String title;
  final List<RoundEndRow> rows;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Color background;
  final Color accent;

  static String signed(int value) => value > 0 ? '+$value' : '$value';

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0x99000000),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: background,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: Colors.black, width: 4),
                boxShadow: const [
                  BoxShadow(color: Colors.black, offset: Offset(0, 7)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black, width: 2),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        color: Color(0xFF17213D),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Bangers',
                      color: Colors.white,
                      fontSize: 34,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      for (final row in rows)
                        Expanded(
                          child: Container(
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: row.highlight
                                  ? accent.withValues(alpha: 0.35)
                                  : Colors.black26,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Text(
                                  row.name.toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w900,
                                    fontSize: 11,
                                  ),
                                ),
                                Text(
                                  signed(row.delta),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (row.reason != null)
                                  Text(
                                    row.reason!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 10,
                                    ),
                                  ),
                                Text(
                                  'Total ${row.total}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 10,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  DialogButton(label: primaryLabel, onTap: onPrimary),
                  if (secondaryLabel != null && onSecondary != null)
                    TextButton(
                      onPressed: onSecondary,
                      child: Text(
                        secondaryLabel!,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

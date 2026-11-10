import 'package:flutter/material.dart';

import '../../widgets/texture_patterns.dart';

const _woodColor = Color(0xFF8B4513);
const _inkColor = Color(0xFF78350F);
const _purpleColor = Color(0xFF7E22CE);

/// Une section des règles (Rules.tsx). Le texte est repris tel quel ; « ** » encadre le gras.
typedef _RuleSection = ({String title, String? paragraph, List<String> items});

const _chkobbaRules = <_RuleSection>[
  (
    title: '🎴 Le Jeu',
    paragraph:
        'La Chkobba se joue avec 40 cartes italiennes (ou espagnoles). '
        'Le but est de ramasser le plus de cartes possible et de marquer des points.',
    items: [],
  ),
  (
    title: '🎯 Objectif',
    paragraph: 'Être le premier joueur à atteindre 11 points (ou plus selon les variantes).',
    items: [],
  ),
  (
    title: '📋 Distribution',
    paragraph: null,
    items: [
      'Chaque joueur reçoit 3 cartes',
      '4 cartes sont placées sur le tapis au centre',
      'Les cartes sont redistribuées quand les mains sont vides',
    ],
  ),
  (
    title: '🎮 Comment Jouer',
    paragraph: null,
    items: [
      'À votre tour, jouez une carte de votre main',
      'Ramassez les cartes du tapis dont la somme égale votre carte',
      'Si une carte de même valeur est sur le tapis, vous devez la prendre en priorité',
      'Si vous ramassez toutes les cartes du tapis : **Chkobba !** (+1 point), sauf avec la dernière carte de la manche',
      'Si vous ne pouvez rien ramasser, votre carte reste sur le tapis',
      'En fin de manche, les cartes restantes vont au dernier joueur qui a ramassé',
    ],
  ),
  (
    title: '🏆 Points',
    paragraph: null,
    items: [
      '**Chkobba :** 1 point (quand vous videz le tapis)',
      '**Plus de cartes :** 1 point (celui qui a ramassé le plus)',
      '**Plus de deniers (♦) :** 1 point',
      '**7 de deniers (Haya) :** 1 point',
      "**Bermila :** 1 point (le plus de 7, ou le plus de 6 en cas d'égalité)",
    ],
  ),
  (
    title: '💎 Valeurs des Cartes',
    paragraph: 'As = 1, 2-7 = valeur nominale, Valet = 8, Cavalier = 9, Roi = 10',
    items: [],
  ),
];

/// Règles de la Chkobba (Rules.tsx), ouvertes depuis l'écran de jeu.
class ChkobbaRulesScreen extends StatelessWidget {
  const ChkobbaRulesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _woodColor,
      body: Stack(
        children: [
          const Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(color: _woodColor))),
          const Positioned.fill(
            child: IgnorePointer(
              child: Opacity(opacity: 0.2, child: DotPattern(spacing: 4, radius: 1, color: Colors.black)),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: _BackButton(onTap: () => Navigator.of(context).pop()),
                      ),
                      const SizedBox(height: 12),
                      const _TitleCard(),
                      const SizedBox(height: 16),
                      _SectionsCard(sections: _chkobbaRules),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 3),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 5))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.arrow_back, size: 18, color: _purpleColor),
                SizedBox(width: 8),
                Text(
                  'Retour au Menu',
                  style: TextStyle(color: _purpleColor, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TitleCard extends StatelessWidget {
  const _TitleCard();

  @override
  Widget build(BuildContext context) {
    // Contour noir en huit directions, comme le text-shadow du source.
    const outline = [
      Shadow(color: Colors.black, offset: Offset(4, 4)),
      Shadow(color: Colors.black, offset: Offset(-2, -2)),
      Shadow(color: Colors.black, offset: Offset(2, -2)),
      Shadow(color: Colors.black, offset: Offset(-2, 2)),
      Shadow(color: Colors.black, offset: Offset(2, 2)),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFACC15), Color(0xFFFBBF24), Color(0xFFFB923C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 6),
        boxShadow: const [BoxShadow(color: Colors.black, offset: Offset(0, 10))],
      ),
      child: const Text(
        'Règles de la Chkobba',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white,
          fontSize: 30,
          fontWeight: FontWeight.w900,
          height: 1.15,
          shadows: outline,
        ),
      ),
    );
  }
}

class _SectionsCard extends StatelessWidget {
  const _SectionsCard({required this.sections});

  final List<_RuleSection> sections;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 18),
            _Section(section: sections[i]),
          ],
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({required this.section});

  final _RuleSection section;

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(color: _inkColor, fontSize: 15, height: 1.4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: const TextStyle(color: _inkColor, fontSize: 21, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 6),
        if (section.paragraph != null) Text(section.paragraph!, style: body),
        for (final item in section.items)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, right: 8),
                  child: Text('•', style: body),
                ),
                Expanded(child: _RichLine(text: item, style: body)),
              ],
            ),
          ),
      ],
    );
  }
}

/// Texte avec gras entre « ** ». Les segments impairs sont en gras.
class _RichLine extends StatelessWidget {
  const _RichLine({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    final parts = text.split('**');
    return Text.rich(
      TextSpan(
        style: style,
        children: [
          for (var i = 0; i < parts.length; i++)
            TextSpan(
              text: parts[i],
              style: i.isOdd ? const TextStyle(fontWeight: FontWeight.w900) : null,
            ),
        ],
      ),
    );
  }
}

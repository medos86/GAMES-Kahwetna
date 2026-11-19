import 'package:material_ui/material_ui.dart';

import '../../core/services/profile_store.dart';
import '../../core/services/pseudo.dart';
import '../../core/strings.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/pressable.dart';

/// Section « Profil » des Paramètres (issue #547) : pseudo éditable, avatar cliquable.
/// [onPickAvatar] ouvre la grille de choix (issue #548).
class ProfileSection extends StatefulWidget {
  const ProfileSection({super.key, this.onPickAvatar});

  final VoidCallback? onPickAvatar;

  @override
  State<ProfileSection> createState() => _ProfileSectionState();
}

class _ProfileSectionState extends State<ProfileSection> {
  final TextEditingController _controller = TextEditingController();
  PlayerProfile? _profile;
  String? _error;

  @override
  void initState() {
    super.initState();
    loadProfile().then((profile) {
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _controller.text = profile.name;
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final profile = _profile;
    if (profile == null) return;
    final name = _controller.text.trim();
    final error = validatePseudo(name);
    if (error != null) {
      setState(() => _error = _messageFor(error));
      return;
    }
    final updated = PlayerProfile(name: name, avatarId: profile.avatarId);
    await saveProfile(updated);
    if (!mounted) return;
    setState(() {
      _profile = updated;
      _error = null;
    });
  }

  String _messageFor(PseudoError error) {
    return switch (error) {
      PseudoError.tooShort => Strings.pseudoTooShort,
      PseudoError.tooLong => Strings.pseudoTooLong,
      PseudoError.invalidCharacters => Strings.pseudoInvalid,
      PseudoError.forbiddenWord => Strings.pseudoForbidden,
    };
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    if (profile == null) return const SizedBox(height: 96);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.profileSection.toUpperCase(),
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            letterSpacing: 1,
            color: ComicPalette.ink,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Pressable(
              semanticLabel: Strings.profileChangeAvatar,
              onTap: widget.onPickAvatar ?? () {},
              child: AvatarView(
                avatarId: profile.avatarId,
                size: 72,
                semanticLabel: profile.name,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: TextField(
                controller: _controller,
                maxLength: pseudoMaxLength,
                decoration: InputDecoration(
                  labelText: Strings.profileName,
                  errorText: _error,
                  counterText: '',
                ),
                onEditingComplete: () => _save(),
              ),
            ),
            TextButton(
              onPressed: () => _save(),
              child: Text(Strings.profileSave),
            ),
          ],
        ),
      ],
    );
  }
}

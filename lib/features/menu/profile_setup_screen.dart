import 'package:material_ui/material_ui.dart';

import '../../core/services/profile_store.dart';
import '../../core/services/pseudo.dart';
import '../../core/strings.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/avatar_view.dart';
import '../../widgets/comic/comic_backdrop.dart';
import '../../widgets/comic/comic_panel.dart';
import '../../widgets/pressable.dart';
import '../settings/avatar_picker.dart';
import '../settings/pseudo_messages.dart';

/// Écran de saisie du pseudo au premier lancement (issue #631).
///
/// Le pseudo est obligatoire : pas de bouton « Passer », retour arrière bloqué.
/// Les règles de validation sont celles de #543. L'avatar tiré au hasard peut
/// être changé ici. Renvoie le [PlayerProfile] saisi ; l'appelant l'enregistre.
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key, required this.initial});

  final PlayerProfile initial;

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final TextEditingController _controller = TextEditingController();
  late String _avatarId = widget.initial.avatarId;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickAvatar() async {
    final chosen = await showAvatarPicker(context, currentId: _avatarId);
    if (chosen == null || !mounted) return;
    setState(() => _avatarId = chosen);
  }

  void _start() {
    final name = _controller.text.trim();
    final error = validatePseudo(name);
    if (error != null) {
      setState(() => _error = pseudoErrorMessage(error));
      return;
    }
    Navigator.of(context).pop(PlayerProfile(name: name, avatarId: _avatarId));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Directionality(
        textDirection: TextDirection.ltr,
        child: Scaffold(
          backgroundColor: ComicPalette.paper,
          body: ComicBackdrop(
            child: SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ComicPanel(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          Strings.setupTitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 22,
                            color: ComicPalette.ink,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          Strings.setupBody,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: ComicPalette.ink),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: Pressable(
                            semanticLabel: Strings.profileChangeAvatar,
                            onTap: () => _pickAvatar(),
                            child: AvatarView(
                              avatarId: _avatarId,
                              size: 96,
                              semanticLabel: Strings.profileChangeAvatar,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        TextField(
                          controller: _controller,
                          autofocus: true,
                          maxLength: pseudoMaxLength,
                          style: const TextStyle(
                            color: ComicPalette.ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                          cursorColor: ComicPalette.ink,
                          decoration: InputDecoration(
                            labelText: Strings.profileName,
                            labelStyle: const TextStyle(
                              color: ComicPalette.ink,
                            ),
                            floatingLabelStyle: const TextStyle(
                              color: ComicPalette.ink,
                              fontWeight: FontWeight.w700,
                            ),
                            errorText: _error,
                            counterText: '',
                            filled: true,
                            fillColor: ComicPalette.white,
                            enabledBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: ComicPalette.ink,
                                width: 2,
                              ),
                            ),
                            focusedBorder: const OutlineInputBorder(
                              borderSide: BorderSide(
                                color: ComicPalette.tunisBlue,
                                width: 3,
                              ),
                            ),
                          ),
                          onSubmitted: (_) => _start(),
                        ),
                        const SizedBox(height: 16),
                        FilledButton(
                          onPressed: _start,
                          child: Text(Strings.setupStart),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

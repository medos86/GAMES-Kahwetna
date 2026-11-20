import 'package:material_ui/material_ui.dart';

import '../../core/strings.dart';
import '../../core/theme/comic_palette.dart';
import '../../widgets/comic/comic_backdrop.dart';
import 'profile_section.dart';

/// Écran Profil (issue #638) : ouvert par la pastille avatar + pseudo du menu.
/// Il ne contient que la section Profil ; « Configuration » ouvre les Paramètres complets.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.ltr,
      child: Scaffold(
        backgroundColor: ComicPalette.paper,
        appBar: AppBar(
          backgroundColor: ComicPalette.paper,
          foregroundColor: ComicPalette.ink,
          elevation: 0,
          title: Text(
            Strings.profileSection,
            style: const TextStyle(
              fontWeight: FontWeight.w900,
              color: ComicPalette.ink,
            ),
          ),
        ),
        body: ComicBackdrop(
          child: const SafeArea(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ProfileSection(),
            ),
          ),
        ),
      ),
    );
  }
}

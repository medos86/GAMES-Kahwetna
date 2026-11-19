import 'package:material_ui/material_ui.dart';

import 'avatar_view.dart';
import 'pressable.dart';

/// Pastille « avatar + pseudo » du menu (issue #546). Tap : ouvre les réglages du profil.
class ProfileChip extends StatelessWidget {
  const ProfileChip({
    super.key,
    required this.name,
    required this.avatarId,
    required this.onTap,
  });

  final String name;
  final String avatarId;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Pressable(
        semanticLabel: name,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(4, 4, 12, 4),
          decoration: BoxDecoration(
            color: const Color(0x66141630),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white, width: 2),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AvatarView(avatarId: avatarId, size: 40, semanticLabel: name),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

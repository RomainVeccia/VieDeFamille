/// Avatars organisés par paliers de points (tous les 100 pts)
class AvatarTier {
  final int requiredPoints;
  final String label;
  final String badge;
  final List<String> emojis;

  const AvatarTier({
    required this.requiredPoints,
    required this.label,
    required this.badge,
    required this.emojis,
  });
}

class FamilyAvatars {
  FamilyAvatars._();

  static const List<AvatarTier> tiers = [
    AvatarTier(
      requiredPoints: 0,
      label: 'Famille',
      badge: '🏠',
      emojis: ['👨', '👩', '👦', '👧', '👶', '🧑', '👴', '👵', '🧒', '👱'],
    ),
    AvatarTier(
      requiredPoints: 100,
      label: 'Animaux mignons',
      badge: '🐾',
      emojis: ['🐱', '🐶', '🐰', '🐹', '🐸', '🐧', '🦜', '🐠', '🐝', '🐿️'],
    ),
    AvatarTier(
      requiredPoints: 200,
      label: 'Animaux sauvages',
      badge: '🌿',
      emojis: ['🦊', '🐼', '🦁', '🐯', '🦝', '🐨', '🐺', '🦦', '🦔', '🐻'],
    ),
    AvatarTier(
      requiredPoints: 300,
      label: 'Créatures magiques',
      badge: '✨',
      emojis: ['🦄', '🐲', '🧙', '🧚', '🧜', '🧝', '🦸', '🦹', '🧛', '🧞'],
    ),
    AvatarTier(
      requiredPoints: 400,
      label: 'Aventuriers',
      badge: '🚀',
      emojis: ['🚀', '🌟', '⚡', '🔥', '🌈', '🏆', '💎', '🎭', '🌙', '👾'],
    ),
    AvatarTier(
      requiredPoints: 500,
      label: 'Légendaires',
      badge: '👑',
      emojis: ['👑', '🎯', '🦅', '🐉', '🍀', '🌺', '🎸', '🎨', '🌊', '⭐'],
    ),
  ];

  /// Liste plate — rétrocompatible avec avatarIndex stocké dans Member
  static List<String> get emojis =>
      tiers.expand((t) => t.emojis).toList();

  /// Retourne l'emoji à l'index donné
  static String get(int index) {
    final list = emojis;
    return list[index % list.length];
  }

  /// Tier contenant cet index
  static int tierIndexFor(int avatarIndex) {
    final idx = avatarIndex % emojis.length;
    int offset = 0;
    for (int i = 0; i < tiers.length; i++) {
      offset += tiers[i].emojis.length;
      if (idx < offset) return i;
    }
    return tiers.length - 1;
  }

  /// Points requis pour débloquer cet avatar
  static int requiredPointsFor(int avatarIndex) =>
      tiers[tierIndexFor(avatarIndex)].requiredPoints;

  /// Cet avatar est-il débloqué pour ce total de points ?
  static bool isUnlocked(int avatarIndex, int totalPoints) =>
      totalPoints >= requiredPointsFor(avatarIndex);
}

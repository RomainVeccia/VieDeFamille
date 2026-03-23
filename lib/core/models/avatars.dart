/// Liste d'avatars emoji pour les membres de la famille
class FamilyAvatars {
  FamilyAvatars._();

  static const List<String> emojis = [
    '👨', '👩', '👦', '👧', '👶', '🧑', '👴', '👵',
    '🐱', '🐶', '🦊', '🐼', '🦁', '🐰', '🐻', '🦄',
  ];

  /// Returns the emoji at the given index (wraps around)
  static String get(int index) => emojis[index % emojis.length];
}

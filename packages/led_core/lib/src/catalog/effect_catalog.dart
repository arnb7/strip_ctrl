enum EffectCategory {
  staticColor('Static'),
  jumping('Jumping'),
  crossFade('Cross Fade'),
  gradual('Gradual'),
  strobe('Strobe Flash');

  final String label;
  const EffectCategory(this.label);
}

class EffectInfo {
  final int index;
  final String name;
  final EffectCategory category;
  final bool isStrobe;

  const EffectInfo({
    required this.index,
    required this.name,
    required this.category,
    required this.isStrobe,
  });

  /// Byte value sent in protocol: (index + 0x80)
  int get protocolByte => (index + 0x80) & 0xFF;
}

class EffectCatalog {
  static const List<EffectInfo> effects = <EffectInfo>[
    EffectInfo(
        index: 0,
        name: 'Static Red',
        category: EffectCategory.staticColor,
        isStrobe: false),
    EffectInfo(
        index: 1,
        name: 'Static Blue',
        category: EffectCategory.staticColor,
        isStrobe: false),
    EffectInfo(
        index: 2,
        name: 'Static Green',
        category: EffectCategory.staticColor,
        isStrobe: false),
    EffectInfo(
        index: 3,
        name: 'Static Cyan',
        category: EffectCategory.staticColor,
        isStrobe: false),
    EffectInfo(
        index: 4,
        name: 'Static Yellow',
        category: EffectCategory.staticColor,
        isStrobe: false),
    EffectInfo(
        index: 5,
        name: 'Static Purple',
        category: EffectCategory.staticColor,
        isStrobe: false),
    EffectInfo(
        index: 6,
        name: 'Static White',
        category: EffectCategory.staticColor,
        isStrobe: false),
    EffectInfo(
        index: 7,
        name: 'RGB Jump (Three Color Jump)',
        category: EffectCategory.jumping,
        isStrobe: false),
    EffectInfo(
        index: 8,
        name: 'Rainbow Cycle (Seven Color Jump)',
        category: EffectCategory.jumping,
        isStrobe: false),
    EffectInfo(
        index: 9,
        name: 'RGB Fade (Three Color Cross Fade)',
        category: EffectCategory.crossFade,
        isStrobe: false),
    EffectInfo(
        index: 10,
        name: 'Rainbow (Seven Color Cross Fade)',
        category: EffectCategory.crossFade,
        isStrobe: false),
    EffectInfo(
        index: 11,
        name: 'Red Gradual Change',
        category: EffectCategory.gradual,
        isStrobe: false),
    EffectInfo(
        index: 12,
        name: 'Green Gradual Change',
        category: EffectCategory.gradual,
        isStrobe: false),
    EffectInfo(
        index: 13,
        name: 'Blue Gradual Change',
        category: EffectCategory.gradual,
        isStrobe: false),
    EffectInfo(
        index: 14,
        name: 'Yellow Gradual Change',
        category: EffectCategory.gradual,
        isStrobe: false),
    EffectInfo(
        index: 15,
        name: 'Cyan Gradual Change',
        category: EffectCategory.gradual,
        isStrobe: false),
    EffectInfo(
        index: 16,
        name: 'Purple Gradual Change',
        category: EffectCategory.gradual,
        isStrobe: false),
    EffectInfo(
        index: 17,
        name: 'White Gradual Change',
        category: EffectCategory.gradual,
        isStrobe: false),
    EffectInfo(
        index: 18,
        name: 'Red Green Cross Fade',
        category: EffectCategory.crossFade,
        isStrobe: false),
    EffectInfo(
        index: 19,
        name: 'Red Blue Cross Fade',
        category: EffectCategory.crossFade,
        isStrobe: false),
    EffectInfo(
        index: 20,
        name: 'Green Blue Cross Fade',
        category: EffectCategory.crossFade,
        isStrobe: false),
    EffectInfo(
        index: 21,
        name: 'Rainbow Strobe (Seven Color)',
        category: EffectCategory.strobe,
        isStrobe: true),
    EffectInfo(
        index: 22,
        name: 'Red Strobe Flash',
        category: EffectCategory.strobe,
        isStrobe: true),
    EffectInfo(
        index: 23,
        name: 'Green Strobe Flash',
        category: EffectCategory.strobe,
        isStrobe: true),
    EffectInfo(
        index: 24,
        name: 'Blue Strobe Flash',
        category: EffectCategory.strobe,
        isStrobe: true),
    EffectInfo(
        index: 25,
        name: 'Yellow Strobe Flash',
        category: EffectCategory.strobe,
        isStrobe: true),
    EffectInfo(
        index: 26,
        name: 'Cyan Strobe Flash',
        category: EffectCategory.strobe,
        isStrobe: true),
    EffectInfo(
        index: 27,
        name: 'Purple Strobe Flash',
        category: EffectCategory.strobe,
        isStrobe: true),
    EffectInfo(
        index: 28,
        name: 'White Strobe Flash',
        category: EffectCategory.strobe,
        isStrobe: true),
  ];

  static EffectInfo? byIndex(int index) {
    if (index >= 0 && index < effects.length) {
      return effects[index];
    }
    return null;
  }

  static EffectInfo? byName(String name) {
    final lower = name.trim().toLowerCase();
    for (final e in effects) {
      if (e.name.toLowerCase() == lower) {
        return e;
      }
    }
    return null;
  }

  static List<EffectInfo> byCategory(EffectCategory category) {
    return effects.where((e) => e.category == category).toList();
  }

  static List<EffectInfo> search(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return effects;
    return effects.where((e) => e.name.toLowerCase().contains(q)).toList();
  }
}

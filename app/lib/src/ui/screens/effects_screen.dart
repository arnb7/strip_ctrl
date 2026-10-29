import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import '../../providers/device_state_provider.dart';
import '../widgets/photosensitivity_dialog.dart';

class _PhoneAnimationDef {
  final String id;
  final String name;
  final String description;
  final IconData icon;
  final Color baseColor;

  const _PhoneAnimationDef({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    required this.baseColor,
  });
}

const _phoneAnimations = <_PhoneAnimationDef>[
  _PhoneAnimationDef(
    id: 'rainbow-drift',
    name: 'Rainbow Drift',
    description: 'Slow hue rotation across the full spectrum (16 FPS)',
    icon: Icons.looks,
    baseColor: Colors.deepPurpleAccent,
  ),
  _PhoneAnimationDef(
    id: 'breathe',
    name: 'Breathe',
    description: 'Current color gently pulsing in and out at 0.4 Hz',
    icon: Icons.air,
    baseColor: Colors.cyanAccent,
  ),
  _PhoneAnimationDef(
    id: 'candle',
    name: 'Candle',
    description: 'Warm organic flame flicker with candle temperature',
    icon: Icons.local_fire_department,
    baseColor: Colors.orangeAccent,
  ),
  _PhoneAnimationDef(
    id: 'aurora',
    name: 'Aurora',
    description: 'Pastel hues drifting with soft brightness wave',
    icon: Icons.wb_twilight,
    baseColor: Colors.tealAccent,
  ),
  _PhoneAnimationDef(
    id: 'alarm',
    name: 'Alarm Pulse',
    description: 'Sharp red pulse at a safe, non-seizure 1 Hz',
    icon: Icons.warning_amber,
    baseColor: Colors.redAccent,
  ),
  _PhoneAnimationDef(
    id: 'fire',
    name: 'Fireplace',
    description: 'Randomized ember & flame brightness dynamics',
    icon: Icons.whatshot,
    baseColor: Colors.deepOrangeAccent,
  ),
];

class EffectsScreen extends ConsumerStatefulWidget {
  const EffectsScreen({super.key});

  @override
  ConsumerState<EffectsScreen> createState() => _EffectsScreenState();
}

class _EffectsScreenState extends ConsumerState<EffectsScreen> {
  int _selectedTabIndex = 0; // 0 = Firmware, 1 = Phone Animations
  String _searchQuery = '';
  EffectCategory? _selectedCategory;
  final Set<int> _favorites = <int>{7, 8, 9, 10}; // defaults

  String? _activePhoneAnimId;
  Timer? _phoneAnimTimer;
  double _animTime = 0.0;

  @override
  void dispose() {
    _phoneAnimTimer?.cancel();
    super.dispose();
  }

  void _startPhoneAnim(String id) {
    if (_activePhoneAnimId == id) {
      _stopPhoneAnim();
      return;
    }
    _phoneAnimTimer?.cancel();
    setState(() {
      _activePhoneAnimId = id;
      _animTime = 0.0;
    });

    _phoneAnimTimer = Timer.periodic(const Duration(milliseconds: 65), (_) {
      _animTime += 0.065;
      final notifier = ref.read(deviceStateProvider.notifier);
      final state = ref.read(deviceStateProvider);
      final (r, g, b) = _computeAnimRgb(id, _animTime, state);
      notifier.sendDirectMusicFrame(r, g, b);
    });
  }

  void _stopPhoneAnim() {
    _phoneAnimTimer?.cancel();
    _phoneAnimTimer = null;
    setState(() {
      _activePhoneAnimId = null;
    });
  }

  (int, int, int) _computeAnimRgb(String id, double t, DeviceState state) {
    switch (id) {
      case 'rainbow-drift':
        final hue = (t * 24.0) % 360.0;
        final color = HSVColor.fromAHSV(1.0, hue, 1.0, 1.0).toColor();
        return (color.red, color.green, color.blue);

      case 'breathe':
        final k = 0.25 + 0.75 * (0.5 - 0.5 * math.cos(2 * math.pi * t * 0.4));
        final baseR = state.r > 0 ? state.r : 0;
        final baseG = state.g > 0 ? state.g : 180;
        final baseB = state.b > 0 ? state.b : 255;
        return (
          (baseR * k).round().clamp(0, 255),
          (baseG * k).round().clamp(0, 255),
          (baseB * k).round().clamp(0, 255),
        );

      case 'candle':
        final flick = 0.72 +
            0.18 * math.sin(t * 11.3) * _hash01((t * 14).floor()) +
            0.14 * _hash01((t * 9).floor() + 7);
        final k = flick.clamp(0.45, 1.0);
        return ((255 * k).round(), (147 * k).round(), (41 * k).round());

      case 'aurora':
        final hue = (200.0 + t * 12.0) % 360.0;
        final wave =
            (0.6 + 0.4 * math.sin(2 * math.pi * t * 0.18)).clamp(0.35, 1.0);
        final color = HSVColor.fromAHSV(1.0, hue, 0.65, wave).toColor();
        return (color.red, color.green, color.blue);

      case 'alarm':
        final on = (t * 1.0) % 1.0 < 0.4;
        return on ? (255, 0, 0) : (20, 0, 0);

      case 'fire':
        final flick = 0.62 +
            0.28 * _hash01((t * 10).floor()) +
            0.14 * math.sin(t * 17.7 + _hash01((t * 5).floor()) * 6);
        final k = flick.clamp(0.4, 1.0);
        return ((255 * k).round(), (96 * k).round(), (12 * k).round());

      default:
        return (255, 255, 255);
    }
  }

  double _hash01(int n) {
    final x = math.sin(n * 127.1 + 311.7) * 43758.5453;
    return x - x.floor();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceStateProvider);
    final notifier = ref.read(deviceStateProvider.notifier);
    final activeEffect = EffectCatalog.byIndex(state.effectIndex);

    final filtered = EffectCatalog.effects.where((e) {
      if (_selectedCategory != null && e.category != _selectedCategory) {
        return false;
      }
      if (_searchQuery.isNotEmpty &&
          !e.name.toLowerCase().contains(_searchQuery.toLowerCase())) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      body: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Mode switch: Firmware vs Phone
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
                  child: SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(
                        value: 0,
                        label: Text('Firmware Effects (29)'),
                        icon: Icon(Icons.flash_on, size: 16),
                      ),
                      ButtonSegment(
                        value: 1,
                        label: Text('Phone Animations (6)'),
                        icon: Icon(Icons.phone_android, size: 16),
                      ),
                    ],
                    selected: {_selectedTabIndex},
                    onSelectionChanged: (set) {
                      setState(() => _selectedTabIndex = set.first);
                    },
                  ),
                ),

                if (_selectedTabIndex == 1) ...[
                  // Explanatory note
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 6, 14, 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.cyan.withOpacity(0.3)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline,
                            size: 16, color: Colors.cyanAccent),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Phone animations stream live frames and pause on app exit. Use Firmware Effects for effects that persist when app closes.',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active Phone Animation Card
                  if (_activePhoneAnimId != null)
                    Container(
                      margin: const EdgeInsets.all(12),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.cyanAccent),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.stream,
                                  color: Colors.cyanAccent, size: 22),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _phoneAnimations
                                        .firstWhere(
                                            (a) => a.id == _activePhoneAnimId)
                                        .name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15),
                                  ),
                                  const Text('Active (Live 16 FPS stream)',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.cyanAccent)),
                                ],
                              ),
                            ],
                          ),
                          IconButton(
                            icon: const Icon(Icons.stop_circle,
                                color: Colors.redAccent, size: 28),
                            onPressed: _stopPhoneAnim,
                          ),
                        ],
                      ),
                    ),
                ] else ...[
                  // Hardware persistent banner
                  Container(
                    margin: const EdgeInsets.fromLTRB(14, 4, 14, 4),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: const Color(0xFFF97316).withOpacity(0.35)),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.bolt, size: 16, color: Color(0xFFF97316)),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Hardware effects run inside the controller MCU chip. They stay active even after closing this app.',
                            style:
                                TextStyle(fontSize: 11, color: Colors.white70),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active effect mini-player card
                  Container(
                    margin: const EdgeInsets.all(12),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: state.mode == ActiveLedMode.effect
                            ? Colors.deepOrangeAccent
                            : Colors.white12,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  const Icon(Icons.auto_awesome,
                                      color: Colors.deepOrangeAccent, size: 22),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          activeEffect?.name ??
                                              'No Effect Active',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                        ),
                                        Text(
                                          state.mode == ActiveLedMode.effect
                                              ? 'Active (Hardware MCU) • Index ${state.effectIndex}'
                                              : 'Paused (RGB mode active)',
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: Colors.white54),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF27272A),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.white12),
                              ),
                              child: Text(
                                '${state.speed}%',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                  color: Color(0xFFF97316),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.speed,
                                size: 18, color: Colors.white54),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Slider(
                                value: state.speed.toDouble(),
                                min: 0,
                                max: 100,
                                divisions: 100,
                                activeColor: Colors.deepOrangeAccent,
                                onChanged: (val) {
                                  notifier.setSpeed(val.round());
                                },
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Search field
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: TextField(
                      onChanged: (val) => setState(() => _searchQuery = val),
                      decoration: InputDecoration(
                        hintText: 'Search 29 built-in effects...',
                        prefixIcon: const Icon(Icons.search, size: 20),
                        filled: true,
                        fillColor: const Color(0xFF161616),
                        contentPadding: const EdgeInsets.symmetric(vertical: 0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Category Chips
                  SizedBox(
                    height: 38,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      children: [
                        ChoiceChip(
                          label: const Text('All (29)'),
                          selected: _selectedCategory == null,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = null),
                        ),
                        const SizedBox(width: 8),
                        ...EffectCategory.values.map((cat) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: ChoiceChip(
                                label: Text(cat.label),
                                selected: _selectedCategory == cat,
                                onSelected: (_) =>
                                    setState(() => _selectedCategory = cat),
                              ),
                            )),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),

          // Content Sliver: Phone Animations or Firmware Effects Grid
          if (_selectedTabIndex == 1)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final anim = _phoneAnimations[index];
                    final isRunning = _activePhoneAnimId == anim.id;
                    return Card(
                      color: isRunning
                          ? const Color(0xFF1A262E)
                          : const Color(0xFF18181B),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: isRunning
                              ? Colors.cyanAccent
                              : const Color(0xFF27272A),
                        ),
                      ),
                      margin: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        onTap: () => _startPhoneAnim(anim.id),
                        borderRadius: BorderRadius.circular(14),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: anim.baseColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(anim.icon,
                                  color: anim.baseColor, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Text(
                                          anim.name,
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: isRunning
                                                ? Colors.cyanAccent
                                                : Colors.white,
                                          ),
                                        ),
                                        if (isRunning) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: Colors.cyanAccent
                                                  .withOpacity(0.2),
                                              borderRadius:
                                                  BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'STREAMING',
                                              style: TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.cyanAccent,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      anim.description,
                                      style: const TextStyle(
                                          fontSize: 12, color: Colors.white54),
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                isRunning
                                    ? Icons.stop_circle_outlined
                                    : Icons.play_circle_outline,
                                color: isRunning
                                    ? Colors.cyanAccent
                                    : Colors.white38,
                                size: 28,
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _phoneAnimations.length,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(14, 8, 14, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  childAspectRatio: 1.8,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final effect = filtered[index];
                    final isSelected = state.mode == ActiveLedMode.effect &&
                        state.effectIndex == effect.index;
                    final isFav = _favorites.contains(effect.index);
                    final isRainbow = effect.index == 10 ||
                        effect.index == 8 ||
                        effect.index == 21;

                    return InkWell(
                      onTap: () async {
                        _stopPhoneAnim();
                        if (effect.isStrobe) {
                          final confirmed =
                              await PhotosensitivityHelper.checkAndWarn(
                                  context);
                          if (!confirmed) return;
                        }
                        notifier.setEffect(effect.index);
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFF2E241E)
                              : const Color(0xFF181818),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected
                                ? Colors.deepOrangeAccent
                                : (isRainbow
                                    ? Colors.orangeAccent.withOpacity(0.4)
                                    : Colors.white12),
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: effect.isStrobe
                                        ? Colors.amber.withOpacity(0.2)
                                        : (isRainbow
                                            ? Colors.orange.withOpacity(0.2)
                                            : Colors.white10),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (isRainbow) ...[
                                        Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: SweepGradient(
                                              colors: [
                                                Colors.red,
                                                Colors.yellow,
                                                Colors.green,
                                                Colors.blue,
                                                Colors.purple,
                                                Colors.red,
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                      ] else if (effect.isStrobe) ...[
                                        const Icon(Icons.flash_on,
                                            size: 12,
                                            color: Colors.amberAccent),
                                        const SizedBox(width: 2),
                                      ],
                                      Text(
                                        '#${effect.index}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isRainbow
                                              ? const Color(0xFFF97316)
                                              : (effect.isStrobe
                                                  ? Colors.amberAccent
                                                  : Colors.white60),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isFav) {
                                        _favorites.remove(effect.index);
                                      } else {
                                        _favorites.add(effect.index);
                                      }
                                    });
                                  },
                                  child: Icon(
                                    isFav ? Icons.star : Icons.star_border,
                                    size: 18,
                                    color: isFav
                                        ? Colors.amberAccent
                                        : Colors.white30,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              effect.name,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSelected
                                    ? Colors.deepOrangeAccent
                                    : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: filtered.length,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:led_core/led_core.dart';
import '../../providers/device_state_provider.dart';
import '../widgets/hsv_color_wheel.dart';

class ControlScreen extends ConsumerStatefulWidget {
  const ControlScreen({super.key});

  @override
  ConsumerState<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends ConsumerState<ControlScreen> {
  final TextEditingController _hexController = TextEditingController();
  final List<Color> _recents = [];
  List<Color> _photoColors = [];
  final bool _usePerceptualBrightness = false;
  bool _showSliders = false;

  // 16 Workspace2 Swatches
  static const List<Color> _swatches = [
    Color(0xFFFF3B30),
    Color(0xFFFF9500),
    Color(0xFFFFCC00),
    Color(0xFF78DC64),
    Color(0xFF34C759),
    Color(0xFF00E1A0),
    Color(0xFF32ADE6),
    Color(0xFF5AC8FA),
    Color(0xFFAF52DE),
    Color(0xFFFF73DF),
    Color(0xFFFF3897),
    Color(0xFFAF7A5A),
    Color(0xFF826953),
    Color(0xFFFFD6AA),
    Color(0xFFFFF7F0),
    Color(0xFF787880),
  ];

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  void _applyColor(Color c, {bool remember = true}) {
    ref.read(deviceStateProvider.notifier).setRgb(c.red, c.green, c.blue);
    if (remember) {
      setState(() {
        _recents.removeWhere((x) => x.value == c.value);
        _recents.insert(0, c);
        if (_recents.length > 8) _recents.removeLast();
      });
    }
  }

  void _onHexSubmit() {
    var text = _hexController.text.trim();
    if (text.startsWith('#')) text = text.substring(1);
    if (text.length == 6) {
      final val = int.tryParse(text, radix: 16);
      if (val != null) {
        final r = (val >> 16) & 0xFF;
        final g = (val >> 8) & 0xFF;
        final b = val & 0xFF;
        _applyColor(Color.fromARGB(255, r, g, b));
        _hexController.clear();
        return;
      }
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Invalid hex color — use #RRGGBB')),
    );
  }

  Future<void> _pickPhoto() async {
    try {
      final picker = ImagePicker();
      final xfile = await picker.pickImage(source: ImageSource.gallery);
      if (xfile == null) return;

      final bytes = await xfile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes, targetWidth: 64, targetHeight: 64);
      final frame = await codec.getNextFrame();
      final byteData = await frame.image.toByteData(format: ui.ImageByteFormat.rawRgba);
      if (byteData == null) return;

      final extracted = <Color>[];
      final pixelCount = byteData.lengthInBytes ~/ 4;

      for (int i = 0; i < pixelCount; i += 8) {
        final r = byteData.getUint8(i * 4);
        final g = byteData.getUint8(i * 4 + 1);
        final b = byteData.getUint8(i * 4 + 2);
        final a = byteData.getUint8(i * 4 + 3);
        if (a < 128) continue;

        final candidate = Color.fromARGB(255, r, g, b);
        final tooClose = extracted.any((c) =>
            (c.red - r).abs() + (c.green - g).abs() + (c.blue - b).abs() < 90);
        if (!tooClose) {
          extracted.add(candidate);
          if (extracted.length >= 6) break;
        }
      }

      if (mounted) {
        setState(() {
          _photoColors = extracted;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Extracted ${extracted.length} colors from photo on-device'),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not read image: $e')),
        );
      }
    }
  }

  // Gamma 2.2 Perceptual Brightness curve conversion
  int _sliderToProtocol(double sliderVal, bool perceptual) {
    if (!perceptual) return sliderVal.round().clamp(0, 100);
    final norm = sliderVal / 100.0;
    final proto = math.pow(norm, 2.2) * 100.0;
    return proto.round().clamp(0, 100);
  }

  double _protocolToSlider(int protoVal, bool perceptual) {
    if (!perceptual) return protoVal.toDouble().clamp(0.0, 100.0);
    final norm = protoVal / 100.0;
    final slider = math.pow(norm, 1.0 / 2.2) * 100.0;
    return slider.clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceStateProvider);
    final notifier = ref.read(deviceStateProvider.notifier);
    final currentColor = Color.fromARGB(255, state.r, state.g, state.b);
    final hexString =
        '#${state.r.toRadixString(16).padLeft(2, '0')}${state.g.toRadixString(16).padLeft(2, '0')}${state.b.toRadixString(16).padLeft(2, '0')}'
            .toUpperCase();

    final currentSliderVal =
        _protocolToSlider(state.brightness, _usePerceptualBrightness);

    return Scaffold(
      backgroundColor: const Color(0xFF09090B),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        child: Column(
          children: [
            // Mode Segmented Button (Color RGB vs White CCT)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SegmentedButton<ActiveLedMode>(
                  style: SegmentedButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    selectedBackgroundColor: const Color(0xFFF97316),
                    selectedForegroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF27272A)),
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ActiveLedMode.color,
                      label: Text('Color RGB'),
                      icon: Icon(Icons.palette_outlined),
                    ),
                    ButtonSegment(
                      value: ActiveLedMode.white,
                      label: Text('White CCT'),
                      icon: Icon(Icons.wb_sunny_outlined),
                    ),
                  ],
                  selected: {
                    state.mode == ActiveLedMode.white
                        ? ActiveLedMode.white
                        : ActiveLedMode.color
                  },
                  onSelectionChanged: (newSelection) {
                    final sel = newSelection.first;
                    if (sel == ActiveLedMode.white) {
                      notifier.setWhite(state.whiteWarm, state.whiteCold);
                    } else {
                      notifier.setRgb(state.r, state.g, state.b);
                    }
                  },
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (state.mode == ActiveLedMode.white) ...[
              // White / CCT Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.wb_sunny_outlined,
                                  size: 18, color: Color(0xFFF97316)),
                              SizedBox(width: 8),
                              Text(
                                'Warm / Cold White',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'The controller mixes white on its RGB channels (hardware-calibrated mix).',
                        style: TextStyle(fontSize: 12, color: Color(0xFFA1A1AA)),
                      ),
                      const SizedBox(height: 20),

                      // Warm White Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Warm White',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF4F4F5))),
                          Text('${state.whiteWarm} / 255',
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Color(0xFFA1A1AA))),
                        ],
                      ),
                      Slider(
                        value: state.whiteWarm.toDouble(),
                        min: 0,
                        max: 255,
                        activeColor: const Color(0xFFFFA657),
                        onChanged: (val) {
                          notifier.setWhite(val.round(), state.whiteCold);
                        },
                      ),
                      const SizedBox(height: 12),

                      // Cold White Slider
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Cold White',
                              style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFF4F4F5))),
                          Text('${state.whiteCold} / 255',
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  color: Color(0xFFA1A1AA))),
                        ],
                      ),
                      Slider(
                        value: state.whiteCold.toDouble(),
                        min: 0,
                        max: 255,
                        activeColor: const Color(0xFFB0D8FF),
                        onChanged: (val) {
                          notifier.setWhite(state.whiteWarm, val.round());
                        },
                      ),
                      const SizedBox(height: 16),

                      // Live CCT Gradient Bar
                      Container(
                        height: 32,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white12),
                          gradient: LinearGradient(
                            colors: const [
                              Color(0xFFFFA657),
                              Color(0xFFB0D8FF),
                            ],
                            stops: [
                              (state.whiteWarm /
                                      math.max(
                                          1, state.whiteWarm + state.whiteCold))
                                  .clamp(0.1, 0.9),
                              1.0,
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ] else ...[
              // Color Wheel & Swatches Card
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.water_drop_outlined,
                                  size: 18, color: Color(0xFFF97316)),
                              SizedBox(width: 8),
                              Text(
                                'Color',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              SegmentedButton<bool>(
                                style: SegmentedButton.styleFrom(
                                  visualDensity: VisualDensity.compact,
                                  backgroundColor: const Color(0xFF09090B),
                                  selectedBackgroundColor: const Color(0xFFF97316),
                                  selectedForegroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF27272A)),
                                ),
                                segments: const [
                                  ButtonSegment(
                                    value: false,
                                    label: Text('Wheel', style: TextStyle(fontSize: 11)),
                                  ),
                                  ButtonSegment(
                                    value: true,
                                    label: Text('Sliders', style: TextStyle(fontSize: 11)),
                                  ),
                                ],
                                selected: {_showSliders},
                                onSelectionChanged: (val) {
                                  setState(() => _showSliders = val.first);
                                },
                              ),
                              const SizedBox(width: 8),
                              Text(
                                hexString,
                                style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFA1A1AA),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (!_showSliders) ...[
                        // HSV Color Wheel (compact 220px to leave plenty of drag/scroll margins)
                        Center(
                          child: RepaintBoundary(
                            child: SizedBox(
                              width: 220,
                              height: 220,
                              child: HsvColorWheel(
                                currentColor: currentColor,
                                power: state.power,
                                onColorChanged: (c) {
                                  _applyColor(c, remember: false);
                                },
                                onTogglePower: () => notifier.togglePower(),
                              ),
                            ),
                          ),
                        ),
                      ] else ...[
                        // Red Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Red',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFF4F4F5))),
                            Text('${state.r} / 255',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Color(0xFFA1A1AA))),
                          ],
                        ),
                        Slider(
                          value: state.r.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.redAccent,
                          onChanged: (val) {
                            _applyColor(
                                Color.fromARGB(255, val.round(), state.g, state.b),
                                remember: false);
                          },
                        ),

                        // Green Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Green',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFF4F4F5))),
                            Text('${state.g} / 255',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Color(0xFFA1A1AA))),
                          ],
                        ),
                        Slider(
                          value: state.g.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.greenAccent,
                          onChanged: (val) {
                            _applyColor(
                                Color.fromARGB(255, state.r, val.round(), state.b),
                                remember: false);
                          },
                        ),

                        // Blue Slider
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Blue',
                                style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFF4F4F5))),
                            Text('${state.b} / 255',
                                style: const TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: 12,
                                    color: Color(0xFFA1A1AA))),
                          ],
                        ),
                        Slider(
                          value: state.b.toDouble(),
                          min: 0,
                          max: 255,
                          activeColor: Colors.blueAccent,
                          onChanged: (val) {
                            _applyColor(
                                Color.fromARGB(255, state.r, state.g, val.round()),
                                remember: false);
                          },
                        ),
                      ],
                      const SizedBox(height: 16),

                      // 16 Workspace2 Swatches
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        alignment: WrapAlignment.center,
                        children: _swatches.map((c) {
                          final isSelected =
                              c.red == state.r && c.green == state.g && c.blue == state.b;
                          return InkWell(
                            onTap: () => _applyColor(c),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: c,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.2),
                                  width: isSelected ? 3 : 1,
                                ),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: c.withValues(alpha: 0.6),
                                          blurRadius: 8,
                                          spreadRadius: 2,
                                        )
                                      ]
                                    : null,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 14),

                      // Pin Order Quick Switcher (Matches user hardware: V+ G R B)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF141416),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF27272A)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              alignment: WrapAlignment.spaceBetween,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              runSpacing: 8,
                              spacing: 8,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                      'Hardware: ',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFFF4F4F5)),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: RichText(
                                        text: const TextSpan(
                                          style: TextStyle(
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.bold,
                                              fontSize: 11),
                                          children: [
                                            TextSpan(
                                                text: 'V+ ',
                                                style: TextStyle(
                                                    color: Colors.white70)),
                                            TextSpan(
                                                text: 'G ',
                                                style: TextStyle(
                                                    color:
                                                        Colors.greenAccent)),
                                            TextSpan(
                                                text: 'R ',
                                                style: TextStyle(
                                                    color: Colors.redAccent)),
                                            TextSpan(
                                                text: 'B',
                                                style: TextStyle(
                                                    color: Colors
                                                        .lightBlueAccent)),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    'GRB',
                                    'RGB',
                                    'BRG',
                                    'BGR',
                                  ].map((order) {
                                    final isSel = state.pinOrder == order;
                                    return Padding(
                                      padding: const EdgeInsets.only(left: 4),
                                      child: InkWell(
                                        onTap: () => notifier.setPinOrder(order),
                                        borderRadius: BorderRadius.circular(6),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 7, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: isSel
                                                ? const Color(0xFFF97316)
                                                : const Color(0xFF27272A),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            order,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isSel
                                                  ? Colors.white
                                                  : const Color(0xFFA1A1AA),
                                            ),
                                          ),
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Text(
                                  'Test Output:',
                                  style: TextStyle(
                                      fontSize: 11, color: Color(0xFF71717A)),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red.shade800,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                  ),
                                  onPressed: () => notifier.setRgb(255, 0, 0),
                                  child: const Text('Test R',
                                      style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green.shade800,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                  ),
                                  onPressed: () => notifier.setRgb(0, 255, 0),
                                  child: const Text('Test G',
                                      style: TextStyle(fontSize: 11)),
                                ),
                                const SizedBox(width: 6),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue.shade800,
                                    foregroundColor: Colors.white,
                                    visualDensity: VisualDensity.compact,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                  ),
                                  onPressed: () => notifier.setRgb(0, 0, 255),
                                  child: const Text('Test B',
                                      style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),

                      // Hex Input + Apply + Photo button
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _hexController,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontFamily: 'monospace',
                                  color: Colors.white),
                              decoration: InputDecoration(
                                hintText: '#RRGGBB',
                                hintStyle:
                                    const TextStyle(color: Color(0xFF71717A)),
                                prefixIcon: const Icon(Icons.tag,
                                    size: 16, color: Color(0xFF71717A)),
                                filled: true,
                                fillColor: const Color(0xFF09090B),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 10),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Color(0xFF27272A)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide:
                                      const BorderSide(color: Color(0xFF27272A)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF27272A),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: _onHexSubmit,
                            child: const Text('Apply'),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: const BorderSide(color: Color(0xFF27272A)),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 12),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10)),
                            ),
                            icon: const Icon(Icons.camera_alt_outlined,
                                size: 16),
                            label: const Text('Photo'),
                            onPressed: _pickPhoto,
                          ),
                        ],
                      ),

                      // Photo Extracted Palette Row
                      if (_photoColors.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        const Text(
                          'From your photo (processed on-device):',
                          style: TextStyle(
                              fontSize: 11, color: Color(0xFFA1A1AA)),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: _photoColors.map((c) {
                            return InkWell(
                              onTap: () => _applyColor(c),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.2)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],

                      // Recents Row
                      if (_recents.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recent:',
                              style: TextStyle(
                                  fontSize: 11, color: Color(0xFFA1A1AA)),
                            ),
                            IconButton(
                              icon: const Icon(Icons.cleaning_services_outlined,
                                  size: 15, color: Color(0xFF71717A)),
                              tooltip: 'Clear recents',
                              onPressed: () => setState(() => _recents.clear()),
                            ),
                          ],
                        ),
                        Wrap(
                          spacing: 8,
                          children: _recents.map((c) {
                            return InkWell(
                              onTap: () => _applyColor(c),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                width: 30,
                                height: 30,
                                decoration: BoxDecoration(
                                  color: c,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: Colors.white.withValues(alpha: 0.15)),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Brightness Card with Perceptual Curve
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.wb_sunny_outlined,
                                size: 18, color: Color(0xFFF97316)),
                            SizedBox(width: 8),
                            Text(
                              'Brightness',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: '-5%',
                              onPressed: () {
                                final next = (state.brightness - 5).clamp(0, 100);
                                notifier.setBrightness(next);
                              },
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: const Icon(Icons.add, size: 18),
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              tooltip: '+5%',
                              onPressed: () {
                                final next = (state.brightness + 5).clamp(0, 100);
                                notifier.setBrightness(next);
                              },
                            ),
                            const SizedBox(width: 10),
                            Text(
                              '${state.brightness}%',
                              style: const TextStyle(
                                  fontFamily: 'monospace',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFA1A1AA)),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Slider(
                      value: currentSliderVal,
                      min: 0,
                      max: 100,
                      activeColor: const Color(0xFFF97316),
                      onChanged: (val) {
                        final proto = _sliderToProtocol(
                            val, _usePerceptualBrightness);
                        notifier.setBrightness(proto);
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('0%',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFF71717A))),
                        Expanded(
                          child: Text(
                            _usePerceptualBrightness
                                ? 'Perceptual curve (gamma 2.2)'
                                : 'Linear',
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10, color: Color(0xFFA1A1AA)),
                          ),
                        ),
                        const Text('100%',
                            style: TextStyle(
                                fontSize: 10, color: Color(0xFF71717A))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

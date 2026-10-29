import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/audio_visualizer_service.dart';
import '../../providers/device_state_provider.dart';
import '../widgets/color_bar.dart';

enum AudioSourceMode { internalAudio, microphone, simulatedBeat }

enum MusicProtocolMode { nativeMusic0x20, dynamicRgb0x10 }

class MusicScreen extends ConsumerStatefulWidget {
  const MusicScreen({super.key});

  @override
  ConsumerState<MusicScreen> createState() => _MusicScreenState();
}

class _MusicScreenState extends ConsumerState<MusicScreen>
    with SingleTickerProviderStateMixin {
  final AudioVisualizerService _audioService = AudioVisualizerService();

  bool _isPlaying = false;
  double _sensitivity = 1.0;
  String _mode = 'Rainbow'; // 'Rainbow', 'Beat Flash', 'Ocean Blue'
  AudioSourceMode _sourceMode = AudioSourceMode.internalAudio;
  MusicProtocolMode _protocolMode = MusicProtocolMode.nativeMusic0x20;

  StreamSubscription<AudioFrame>? _audioSub;
  Timer? _simulatedTimer;

  final List<double> _equalizerBars = List<double>.filled(28, 0.08);
  double _simPhase = 0.0;
  int _colorIndex = 0;

  double _rollingBassAvg = 0.2;
  DateTime _lastBeatTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastDispatchTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Classic Duoco Strip music cycle palette
  static const List<Color> _duocoColors = [
    Color(0xFFFF0000), // Red
    Color(0xFF00FF00), // Green
    Color(0xFF0000FF), // Blue
    Color(0xFFFFFF00), // Yellow
    Color(0xFFFF00FF), // Magenta
    Color(0xFF00FFFF), // Cyan
    Color(0xFFFFFFFF), // White
  ];

  Color _currentActiveColor = const Color(0xFFFF0055);

  @override
  void dispose() {
    _stopAllStreams();
    super.dispose();
  }

  void _stopAllStreams() {
    _audioSub?.cancel();
    _audioSub = null;
    _simulatedTimer?.cancel();
    _simulatedTimer = null;
    _audioService.stopAudio();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      _stopAllStreams();
      setState(() {
        _isPlaying = false;
      });
    } else {
      setState(() {
        _isPlaying = true;
      });
      await _startSelectedStream();
    }
  }

  Future<void> _startSelectedStream() async {
    _stopAllStreams();

    if (_sourceMode == AudioSourceMode.internalAudio) {
      final success = await _audioService.startInternalAudio();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Internal audio visualizer unavailable on this platform/session. Falling back to mic.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        _sourceMode = AudioSourceMode.microphone;
        await _audioService.startMicAudio();
      }
      _listenToAudioStream();
    } else if (_sourceMode == AudioSourceMode.microphone) {
      final success = await _audioService.startMicAudio();
      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone access denied. Falling back to demo beat generator.',
            ),
            duration: Duration(seconds: 3),
          ),
        );
        _sourceMode = AudioSourceMode.simulatedBeat;
        _startSimulatedStream();
        return;
      }
      _listenToAudioStream();
    } else {
      _startSimulatedStream();
    }
  }

  void _listenToAudioStream() {
    _audioSub = _audioService.audioStream.listen(
      (frame) {
        if (!mounted || !_isPlaying) return;
        _processAudioInput(frame.energy, frame.bass, frame.bands);
      },
      onError: (dynamic error) {
        debugPrint('Audio stream listener error: $error');
      },
    );
  }

  void _startSimulatedStream() {
    _simulatedTimer =
        Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted || !_isPlaying) {
        timer.cancel();
        return;
      }

      _simPhase += 0.15;
      final bass = (math.sin(_simPhase * 2.5) * 0.5 + 0.5);
      final energy = (math.sin(_simPhase) * 0.4 + 0.5);

      final mockBands = List<double>.generate(16, (i) {
        final harmonic = math.sin(_simPhase + (i * 0.4)).abs();
        return (harmonic * 0.7 + (i < 4 ? bass * 0.5 : 0.2)).clamp(0.05, 1.0);
      });

      _processAudioInput(energy, bass, mockBands);
    });
  }

  void _processAudioInput(
      double rawEnergy, double rawBass, List<double> bands) {
    final energy = (rawEnergy * _sensitivity).clamp(0.0, 1.0);
    final bass = (rawBass * _sensitivity).clamp(0.0, 1.0);

    // Dynamic smoothing on equalizer bars
    final updatedBars = <double>[];
    for (int i = 0; i < 28; i++) {
      final bandIndex = ((i / 28) * bands.length).floor().clamp(0, bands.length - 1);
      final rawBandVal = (bands[bandIndex] * _sensitivity).clamp(0.05, 1.0);
      final prevVal = _equalizerBars[i];
      // Fast attack, smooth decay
      final smoothed = rawBandVal > prevVal
          ? rawBandVal
          : prevVal * 0.75 + rawBandVal * 0.25;
      updatedBars.add(smoothed.clamp(0.05, 1.0));
    }

    // Beat detection algorithm
    _rollingBassAvg = _rollingBassAvg * 0.90 + bass * 0.10;
    final now = DateTime.now();
    final timeSinceLastBeat = now.difference(_lastBeatTime).inMilliseconds;
    final isBeat =
        bass > (_rollingBassAvg * 1.30) && bass > 0.32 && timeSinceLastBeat > 160;

    if (isBeat) {
      _lastBeatTime = now;
      _colorIndex = (_colorIndex + 1) % _duocoColors.length;
    }

    // Compute RGB color based on selected reactive mode
    Color targetColor;
    if (_mode == 'Rainbow') {
      final hue = ((_simPhase * 40 + energy * 180) % 360).toDouble();
      targetColor = HSVColor.fromAHSV(
        1.0,
        hue,
        1.0,
        energy.clamp(0.2, 1.0),
      ).toColor();
    } else if (_mode == 'Beat Flash') {
      if (isBeat) {
        targetColor = _duocoColors[_colorIndex];
      } else {
        final decay = (timeSinceLastBeat < 400)
            ? (1.0 - (timeSinceLastBeat / 400.0))
            : 0.15;
        final base = _duocoColors[_colorIndex];
        targetColor = Color.fromRGBO(
          (base.r * 255 * decay).round().clamp(0, 255),
          (base.g * 255 * decay).round().clamp(0, 255),
          (base.b * 255 * decay).round().clamp(0, 255),
          1.0,
        );
      }
    } else {
      // Ocean Blue mode
      final brightness = (bass * 0.8 + energy * 0.2).clamp(0.15, 1.0);
      targetColor = Color.fromRGBO(
        0,
        (160 * brightness).round().clamp(0, 255),
        (255 * brightness).round().clamp(0, 255),
        1.0,
      );
    }

    _currentActiveColor = targetColor;

    setState(() {
      _equalizerBars.setAll(0, updatedBars);
    });

    // Throttle BLE transmission to ~35ms minimum spacing to avoid saturating BK3431/JL UART
    if (now.difference(_lastDispatchTime).inMilliseconds >= 35) {
      _lastDispatchTime = now;
      final notifier = ref.read(deviceStateProvider.notifier);
      final r = (targetColor.r * 255.0).round().clamp(0, 255);
      final g = (targetColor.g * 255.0).round().clamp(0, 255);
      final b = (targetColor.b * 255.0).round().clamp(0, 255);

      final useMusic0x20 =
          _protocolMode == MusicProtocolMode.nativeMusic0x20;
      notifier.sendDirectMusicFrame(r, g, b, useMusicByte: useMusic0x20);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceStateProvider);
    final currentColor = _isPlaying
        ? _currentActiveColor
        : Color.fromARGB(255, state.r, state.g, state.b);

    return Scaffold(
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(0, 12, 0, 80),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.waves, size: 18, color: Color(0xFFF97316)),
                  SizedBox(width: 8),
                  Text(
                    'Music Reactive Mode',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Live Strip Preview Bar
            ColorBar(
              color: currentColor,
              brightness: state.brightness,
              power: state.power,
            ),
            const SizedBox(height: 12),

            // Live Equalizer Visualizer Canvas Card
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF141414),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isPlaying
                      ? currentColor.withValues(alpha: 0.6)
                      : Colors.white12,
                  width: 1.5,
                ),
                boxShadow: _isPlaying
                    ? [
                        BoxShadow(
                          color: currentColor.withValues(alpha: 0.25),
                          blurRadius: 24,
                          spreadRadius: 2,
                        )
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.graphic_eq,
                            color: _isPlaying
                                ? Colors.greenAccent
                                : Colors.white38,
                            size: 24,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _isPlaying
                                ? (_sourceMode == AudioSourceMode.internalAudio
                                    ? 'Internal Audio Active'
                                    : _sourceMode == AudioSourceMode.microphone
                                        ? 'Microphone Active'
                                        : 'Demo Beat Active')
                                : 'Music Reactive Paused',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: _isPlaying
                                  ? Colors.greenAccent
                                  : Colors.white60,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _protocolMode == MusicProtocolMode.nativeMusic0x20
                              ? 'CMD 05 (0x20)'
                              : 'CMD 05 (0x10)',
                          style: const TextStyle(
                              fontSize: 10,
                              color: Colors.white70,
                              fontFamily: 'monospace'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Equalizer Bars
                  SizedBox(
                    height: 120,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: List.generate(28, (i) {
                        final val = _equalizerBars[i];
                        final barColor = HSVColor.fromAHSV(
                          1.0,
                          (i * 12.0) % 360,
                          0.9,
                          _isPlaying ? 1.0 : 0.3,
                        ).toColor();

                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 35),
                          width: 6,
                          height: (120 * val).clamp(6.0, 120.0),
                          decoration: BoxDecoration(
                            color: barColor,
                            borderRadius: BorderRadius.circular(3),
                            boxShadow: _isPlaying && val > 0.5
                                ? [
                                    BoxShadow(
                                      color: barColor.withValues(alpha: 0.5),
                                      blurRadius: 6,
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Play/Pause Big Button
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isPlaying
                          ? Colors.redAccent
                          : Colors.deepOrangeAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                    ),
                    icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow,
                        size: 24),
                    label: Text(
                      _isPlaying
                          ? 'Stop Music Reactivity'
                          : 'Start Music Reactivity',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                    onPressed: _togglePlay,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Audio Input Source Selection Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audio Input Source',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Select where audio is captured from. Internal Audio hooks directly into music playing on your phone (Spotify, YouTube, media players).',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            avatar: const Icon(Icons.speaker_group, size: 16),
                            label: const Text('Internal Audio (Device)'),
                            selected: _sourceMode == AudioSourceMode.internalAudio,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() =>
                                    _sourceMode = AudioSourceMode.internalAudio);
                                if (_isPlaying) _startSelectedStream();
                              }
                            },
                          ),
                          ChoiceChip(
                            avatar: const Icon(Icons.mic, size: 16),
                            label: const Text('Phone Mic (Ambient)'),
                            selected: _sourceMode == AudioSourceMode.microphone,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() =>
                                    _sourceMode = AudioSourceMode.microphone);
                                if (_isPlaying) _startSelectedStream();
                              }
                            },
                          ),
                          ChoiceChip(
                            avatar: const Icon(Icons.music_note, size: 16),
                            label: const Text('Demo Beat (Offline Synth)'),
                            selected: _sourceMode == AudioSourceMode.simulatedBeat,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() =>
                                    _sourceMode = AudioSourceMode.simulatedBeat);
                                if (_isPlaying) _startSelectedStream();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Protocol Mode Selection Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'BLE Transmission Protocol',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'If your LED strip does not pulse in 0x20 mode, switch to Dynamic RGB Pulse (0x10) which all ELK-BLEDOM chips support.',
                        style: TextStyle(fontSize: 12, color: Colors.white60),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('Native Music (0x20)'),
                            selected: _protocolMode ==
                                MusicProtocolMode.nativeMusic0x20,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _protocolMode =
                                    MusicProtocolMode.nativeMusic0x20);
                              }
                            },
                          ),
                          ChoiceChip(
                            label: const Text('Dynamic RGB Pulse (0x10)'),
                            selected: _protocolMode ==
                                MusicProtocolMode.dynamicRgb0x10,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _protocolMode =
                                    MusicProtocolMode.dynamicRgb0x10);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Music Settings Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Card(
                color: const Color(0xFF1E1E1E),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Reactivity Mode & Tuning',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sensitivity',
                              style: TextStyle(color: Colors.white70)),
                          Text('${(_sensitivity * 100).round()}%',
                              style:
                                  const TextStyle(fontWeight: FontWeight.bold)),
                        ],
                      ),
                      Slider(
                        value: _sensitivity,
                        min: 0.2,
                        max: 2.0,
                        activeColor: Colors.deepOrangeAccent,
                        onChanged: (v) => setState(() => _sensitivity = v),
                      ),
                      const SizedBox(height: 12),
                      const Text('Color Scheme',
                          style: TextStyle(color: Colors.white70)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children:
                            ['Rainbow', 'Beat Flash', 'Ocean Blue'].map((m) {
                          final isSelected = _mode == m;
                          return ChoiceChip(
                            label: Text(m),
                            selected: isSelected,
                            onSelected: (_) => setState(() => _mode = m),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

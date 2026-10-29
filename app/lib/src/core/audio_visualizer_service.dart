import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class AudioFrame {
  final double energy;
  final double bass;
  final List<double> bands;

  const AudioFrame({
    required this.energy,
    required this.bass,
    required this.bands,
  });

  factory AudioFrame.fromMap(Map<dynamic, dynamic> map) {
    final rawBands = map['bands'] as List<dynamic>?;
    final bandsList = rawBands != null
        ? rawBands.map((e) => (e as num).toDouble()).toList()
        : List<double>.filled(16, (map['energy'] as num?)?.toDouble() ?? 0.0);

    return AudioFrame(
      energy: ((map['energy'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      bass: ((map['bass'] as num?)?.toDouble() ?? 0.0).clamp(0.0, 1.0),
      bands: bandsList,
    );
  }
}

class AudioDspEngine {
  static const int fftSize = 512;
  static final Float64List _cosTable = Float64List(fftSize ~/ 2);
  static final Float64List _sinTable = Float64List(fftSize ~/ 2);
  static final Float64List _hanningWindow = Float64List(fftSize);
  static bool _initialized = false;

  static void _init() {
    if (_initialized) return;
    for (int i = 0; i < fftSize ~/ 2; i++) {
      final angle = -2 * math.pi * i / fftSize;
      _cosTable[i] = math.cos(angle);
      _sinTable[i] = math.sin(angle);
    }
    for (int i = 0; i < fftSize; i++) {
      _hanningWindow[i] =
          0.5 * (1.0 - math.cos(2 * math.pi * i / (fftSize - 1)));
    }
    _initialized = true;
  }

  static AudioFrame process(Int16List samples) {
    _init();
    final real = Float64List(fftSize);
    final imag = Float64List(fftSize);

    double sumSq = 0.0;
    final count = math.min(samples.length, fftSize);
    for (int i = 0; i < count; i++) {
      final s = samples[i] / 32768.0;
      sumSq += s * s;
      real[i] = s * _hanningWindow[i];
    }
    final rms = math.sqrt(sumSq / fftSize);
    final energy = (rms * 2.8).clamp(0.0, 1.0);

    // Cooley-Tukey Radix-2 In-place FFT
    int j = 0;
    for (int i = 0; i < fftSize - 1; i++) {
      if (i < j) {
        final tr = real[i];
        real[i] = real[j];
        real[j] = tr;
        final ti = imag[i];
        imag[i] = imag[j];
        imag[j] = ti;
      }
      int k = fftSize >> 1;
      while (k <= j) {
        j -= k;
        k >>= 1;
      }
      j += k;
    }

    for (int len = 2; len <= fftSize; len <<= 1) {
      final halfLen = len >> 1;
      final step = fftSize ~/ len;
      for (int i = 0; i < fftSize; i += len) {
        for (int k = 0; k < halfLen; k++) {
          final tableIdx = k * step;
          final c = _cosTable[tableIdx];
          final s = _sinTable[tableIdx];
          final uR = real[i + k];
          final uI = imag[i + k];
          final vR = real[i + k + halfLen] * c - imag[i + k + halfLen] * s;
          final vI = real[i + k + halfLen] * s + imag[i + k + halfLen] * c;
          real[i + k] = uR + vR;
          imag[i + k] = uI + vI;
          real[i + k + halfLen] = uR - vR;
          imag[i + k + halfLen] = uI - vI;
        }
      }
    }

    // 16 Logarithmic frequency bands (20Hz .. 8000Hz)
    const boundaries = <int>[
      1, 2, 3, 4, 6, 8, 12, 16, 24, 32, 48, 64, 96, 128, 192, 256
    ];

    final bands = List<double>.filled(16, 0.0);
    double bassSum = 0.0;
    int prevBin = 1;

    for (int b = 0; b < 16; b++) {
      final endBin = boundaries[b];
      double magSum = 0.0;
      int binCount = 0;
      for (int k = prevBin; k < endBin; k++) {
        final mag = math.sqrt(real[k] * real[k] + imag[k] * imag[k]);
        magSum += mag;
        binCount++;
      }
      prevBin = endBin;
      final avgMag = binCount > 0 ? (magSum / binCount) : 0.0;
      final normBand = (avgMag * 0.18).clamp(0.0, 1.0);
      bands[b] = normBand;
      if (b < 4) {
        bassSum += normBand;
      }
    }

    final bass = (bassSum / 4.0).clamp(0.0, 1.0);
    return AudioFrame(energy: energy, bass: bass, bands: bands);
  }
}

class AudioVisualizerService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.stripctl/audio_control');
  static const EventChannel _eventChannel =
      EventChannel('com.example.stripctl/audio_stream');

  Stream<AudioFrame>? _androidStream;
  final StreamController<AudioFrame> _linuxStreamController =
      StreamController<AudioFrame>.broadcast();

  Process? _linuxAudioProcess;
  StreamSubscription<List<int>>? _linuxAudioSub;
  final BytesBuilder _pcmBuffer = BytesBuilder(copy: false);

  Stream<AudioFrame> get audioStream {
    if (Platform.isAndroid) {
      _androidStream ??= _eventChannel
          .receiveBroadcastStream()
          .map((dynamic event) {
            if (event is Map) {
              return AudioFrame.fromMap(event);
            }
            return AudioFrame(
              energy: 0.0,
              bass: 0.0,
              bands: List<double>.filled(16, 0.0),
            );
          })
          .handleError((dynamic error) {
            debugPrint('AudioVisualizerService Android stream error: $error');
          });
      return _androidStream!;
    }
    return _linuxStreamController.stream;
  }

  Future<String?> _resolveSinkNodeId() async {
    // 1. wpctl inspect @DEFAULT_AUDIO_SINK@
    try {
      final res = await Process.run('wpctl', ['inspect', '@DEFAULT_AUDIO_SINK@']);
      if (res.exitCode == 0) {
        final match = RegExp(r'id\s+(\d+)').firstMatch(res.stdout.toString());
        if (match != null) return match.group(1);
      }
    } catch (_) {}

    // 2. pactl list sinks short (matching default or RUNNING)
    try {
      final defaultRes = await Process.run('pactl', ['get-default-sink']);
      final defaultName = defaultRes.stdout.toString().trim();

      final res = await Process.run('pactl', ['list', 'sinks', 'short']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2) {
            if (defaultName.isNotEmpty && parts[1] == defaultName) {
              return parts[0];
            }
            if (parts.contains('RUNNING')) {
              return parts[0];
            }
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<String?> _resolveSourceNodeId() async {
    // 1. wpctl inspect @DEFAULT_AUDIO_SOURCE@
    try {
      final res = await Process.run('wpctl', ['inspect', '@DEFAULT_AUDIO_SOURCE@']);
      if (res.exitCode == 0) {
        final match = RegExp(r'id\s+(\d+)').firstMatch(res.stdout.toString());
        if (match != null) return match.group(1);
      }
    } catch (_) {}

    // 2. pactl list sources short (look for unmuted or RUNNING source)
    try {
      final res = await Process.run('pactl', ['list', 'sources', 'short']);
      if (res.exitCode == 0) {
        final lines = res.stdout.toString().split('\n');
        for (final line in lines) {
          final parts = line.trim().split(RegExp(r'\s+'));
          if (parts.length >= 2 && !parts[1].contains('monitor')) {
            if (parts.contains('RUNNING')) return parts[0];
          }
        }
      }
    } catch (_) {}

    return null;
  }

  Future<bool> startInternalAudio() async {
    if (Platform.isAndroid) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;
      try {
        final success =
            await _methodChannel.invokeMethod<bool>('startInternalAudio');
        return success ?? false;
      } catch (e) {
        debugPrint('Failed to start internal audio on Android: $e');
        return false;
      }
    }

    // Native Linux Desktop Audio capture via PipeWire / PulseAudio monitor
    await stopAudio();
    try {
      final nodeId = await _resolveSinkNodeId();
      final args = <String>[
        if (nodeId != null) ...['--target', nodeId],
        '--raw',
        '--rate=16000',
        '--channels=1',
        '--format=s16',
        '-',
      ];

      Process? proc;
      try {
        proc = await Process.start('pw-record', args);
      } catch (_) {
        // Fallback to parec with monitor device
        try {
          proc = await Process.start('parec', [
            '-d',
            '@DEFAULT_MONITOR@',
            '--raw',
            '--rate=16000',
            '--channels=1',
          ]);
        } catch (_) {}
      }

      if (proc == null) {
        debugPrint('Neither pw-record nor parec available on Linux');
        return false;
      }

      _linuxAudioProcess = proc;
      _startPcmListener(proc.stdout);
      return true;
    } catch (e) {
      debugPrint('Failed to start internal audio on Linux: $e');
      return false;
    }
  }

  Future<bool> startMicAudio() async {
    if (Platform.isAndroid) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;
      try {
        final success =
            await _methodChannel.invokeMethod<bool>('startMicAudio');
        return success ?? false;
      } catch (e) {
        debugPrint('Failed to start mic audio on Android: $e');
        return false;
      }
    }

    // Native Linux Microphone capture via PipeWire / PulseAudio
    await stopAudio();
    try {
      final nodeId = await _resolveSourceNodeId();
      final args = <String>[
        if (nodeId != null) ...['--target', nodeId],
        '--raw',
        '--rate=16000',
        '--channels=1',
        '--format=s16',
        '-',
      ];

      Process? proc;
      try {
        proc = await Process.start('pw-record', args);
      } catch (_) {
        try {
          proc = await Process.start('parec', [
            '-d',
            '@DEFAULT_SOURCE@',
            '--raw',
            '--rate=16000',
            '--channels=1',
          ]);
        } catch (_) {}
      }

      if (proc == null) {
        debugPrint('Neither pw-record nor parec available for mic capture');
        return false;
      }

      _linuxAudioProcess = proc;
      _startPcmListener(proc.stdout);
      return true;
    } catch (e) {
      debugPrint('Failed to start mic audio on Linux: $e');
      return false;
    }
  }

  void _startPcmListener(Stream<List<int>> stdout) {
    _pcmBuffer.clear();
    const frameByteLength = AudioDspEngine.fftSize * 2; // 512 samples * 2 bytes = 1024 bytes

    _linuxAudioSub = stdout.listen(
      (chunk) {
        _pcmBuffer.add(chunk);

        // If buffer accumulated backlog, discard stale bytes to prevent latency and memory loop
        if (_pcmBuffer.length > frameByteLength * 4) {
          final allBytes = _pcmBuffer.takeBytes();
          final recentBytes = Uint8List.sublistView(
            allBytes,
            allBytes.length - (frameByteLength * 2),
          );
          _pcmBuffer.add(recentBytes);
        }

        while (_pcmBuffer.length >= frameByteLength) {
          final allBytes = _pcmBuffer.takeBytes();
          final frameBytes = Uint8List.sublistView(allBytes, 0, frameByteLength);
          final leftover = Uint8List.sublistView(allBytes, frameByteLength);
          _pcmBuffer.add(leftover);

          // Convert bytes to Int16 samples (little-endian)
          final byteData = ByteData.sublistView(frameBytes);
          final samples = Int16List(AudioDspEngine.fftSize);
          for (int i = 0; i < AudioDspEngine.fftSize; i++) {
            samples[i] = byteData.getInt16(i * 2, Endian.little);
          }

          final frame = AudioDspEngine.process(samples);
          if (!_linuxStreamController.isClosed) {
            _linuxStreamController.add(frame);
          }
        }
      },
      onError: (dynamic err) {
        debugPrint('Linux audio stream error: $err');
      },
    );
  }

  Future<void> stopAudio() async {
    if (Platform.isAndroid) {
      try {
        await _methodChannel.invokeMethod<void>('stopAudio');
      } catch (e) {
        debugPrint('Failed to stop audio on Android: $e');
      }
      return;
    }

    await _linuxAudioSub?.cancel();
    _linuxAudioSub = null;
    _pcmBuffer.clear();
    if (_linuxAudioProcess != null) {
      try {
        _linuxAudioProcess!.kill(ProcessSignal.sigterm);
      } catch (_) {}
      _linuxAudioProcess = null;
    }
  }
}

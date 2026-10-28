import 'dart:async';
import 'dart:io';
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

class AudioVisualizerService {
  static const MethodChannel _methodChannel =
      MethodChannel('com.example.stripctl/audio_control');
  static const EventChannel _eventChannel =
      EventChannel('com.example.stripctl/audio_stream');

  Stream<AudioFrame>? _stream;

  Stream<AudioFrame> get audioStream {
    _stream ??= _eventChannel
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
          debugPrint('AudioVisualizerService stream error: $error');
        });
    return _stream!;
  }

  Future<bool> startInternalAudio() async {
    if (!Platform.isAndroid) return false;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Microphone / Audio capture permission denied');
      return false;
    }

    try {
      final success =
          await _methodChannel.invokeMethod<bool>('startInternalAudio');
      return success ?? false;
    } catch (e) {
      debugPrint('Failed to start internal audio: $e');
      return false;
    }
  }

  Future<bool> startMicAudio() async {
    if (!Platform.isAndroid) return false;

    final status = await Permission.microphone.request();
    if (!status.isGranted) {
      debugPrint('Microphone permission denied');
      return false;
    }

    try {
      final success = await _methodChannel.invokeMethod<bool>('startMicAudio');
      return success ?? false;
    } catch (e) {
      debugPrint('Failed to start mic audio: $e');
      return false;
    }
  }

  Future<void> stopAudio() async {
    if (!Platform.isAndroid) return;
    try {
      await _methodChannel.invokeMethod<void>('stopAudio');
    } catch (e) {
      debugPrint('Failed to stop audio: $e');
    }
  }
}

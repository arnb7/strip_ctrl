package com.example.stripctl

import android.Manifest
import android.content.pm.PackageManager
import android.media.AudioFormat
import android.media.AudioRecord
import android.media.MediaRecorder
import android.media.audiofx.Visualizer
import android.os.Handler
import android.os.Looper
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel
import kotlin.concurrent.thread
import kotlin.math.hypot
import kotlin.math.sqrt

class MainActivity : FlutterActivity() {
    private val METHOD_CHANNEL = "com.example.stripctl/audio_control"
    private val EVENT_CHANNEL = "com.example.stripctl/audio_stream"

    private var visualizer: Visualizer? = null
    private var isRecordingMic = false
    private var audioRecord: AudioRecord? = null
    private var eventSink: EventChannel.EventSink? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startInternalAudio" -> {
                    val success = startInternalVisualizer()
                    result.success(success)
                }
                "startMicAudio" -> {
                    val success = startMicCapture()
                    result.success(success)
                }
                "stopAudio" -> {
                    stopAllAudio()
                    result.success(true)
                }
                "isSupported" -> {
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
                stopAllAudio()
            }
        })
    }

    private fun startInternalVisualizer(): Boolean {
        stopAllAudio()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            Log.w("StripCtlAudio", "RECORD_AUDIO permission not granted for Visualizer")
            return false
        }

        return try {
            // Audio session 0 captures the global output mix (internal audio from any media player)
            val vis = Visualizer(0)
            val captureRange = Visualizer.getCaptureSizeRange()
            vis.captureSize = captureRange[1].coerceAtMost(512)

            vis.setDataCaptureListener(object : Visualizer.OnDataCaptureListener {
                override fun onWaveFormDataCapture(v: Visualizer?, waveform: ByteArray?, samplingRate: Int) {
                    if (waveform == null || waveform.isEmpty()) return

                    // Waveform: 8-bit unsigned PCM centered around 128
                    var sumSquares = 0.0
                    for (b in waveform) {
                        val sample = (b.toInt() and 0xFF) - 128
                        sumSquares += (sample * sample).toDouble()
                    }
                    val rms = sqrt(sumSquares / waveform.size) // 0..128
                    val volume = (rms / 64.0).coerceIn(0.0, 1.0)

                    sendAudioEvent(volume, null, volume)
                }

                override fun onFftDataCapture(v: Visualizer?, fft: ByteArray?, samplingRate: Int) {
                    if (fft == null || fft.isEmpty()) return

                    // Compute 16 frequency bands from FFT
                    // fft[0] = DC, fft[1] = Nyquist
                    val bands = DoubleArray(16)
                    val n = fft.size / 2
                    val step = (n / 16).coerceAtLeast(1)

                    var totalMag = 0.0
                    var bassEnergy = 0.0

                    for (i in 0 until 16) {
                        var sum = 0.0
                        val start = i * step + 1
                        val end = ((i + 1) * step).coerceAtMost(n - 1)
                        var count = 0
                        for (k in start..end) {
                            val r = fft[2 * k].toDouble()
                            val im = fft[2 * k + 1].toDouble()
                            val mag = hypot(r, im)
                            sum += mag
                            count++
                        }
                        val avg = if (count > 0) sum / count else 0.0
                        val normalized = (avg / 64.0).coerceIn(0.0, 1.0)
                        bands[i] = normalized
                        totalMag += normalized
                        if (i < 4) {
                            bassEnergy += normalized
                        }
                    }

                    val normalizedEnergy = (totalMag / 16.0).coerceIn(0.0, 1.0)
                    val normalizedBass = (bassEnergy / 4.0).coerceIn(0.0, 1.0)

                    sendAudioEvent(normalizedEnergy, bands.toList(), normalizedBass)
                }
            }, Visualizer.getMaxCaptureRate() / 2, true, true)

            vis.enabled = true
            visualizer = vis
            Log.i("StripCtlAudio", "Visualizer(0) internal audio capture successfully initialized")
            true
        } catch (e: Exception) {
            Log.e("StripCtlAudio", "Failed to start Visualizer(0): ${e.message}, falling back to mic", e)
            startMicCapture()
        }
    }

    private fun startMicCapture(): Boolean {
        stopAllAudio()
        if (ContextCompat.checkSelfPermission(this, Manifest.permission.RECORD_AUDIO) != PackageManager.PERMISSION_GRANTED) {
            return false
        }

        return try {
            val sampleRate = 44100
            val channelConfig = AudioFormat.CHANNEL_IN_MONO
            val audioFormat = AudioFormat.ENCODING_PCM_16BIT
            val minBuf = AudioRecord.getMinBufferSize(sampleRate, channelConfig, audioFormat)
            val bufferSize = minBuf.coerceAtLeast(2048)

            val recorder = AudioRecord(
                MediaRecorder.AudioSource.MIC,
                sampleRate,
                channelConfig,
                audioFormat,
                bufferSize
            )

            if (recorder.state != AudioRecord.STATE_INITIALIZED) {
                recorder.release()
                return false
            }

            recorder.startRecording()
            audioRecord = recorder
            isRecordingMic = true

            thread(name = "StripCtlMicCaptureThread") {
                val shortBuffer = ShortArray(bufferSize / 2)
                while (isRecordingMic) {
                    val readCount = recorder.read(shortBuffer, 0, shortBuffer.size)
                    if (readCount > 0) {
                        var sum = 0.0
                        for (i in 0 until readCount) {
                            val sample = shortBuffer[i].toDouble() / 32768.0
                            sum += sample * sample
                        }
                        val rms = sqrt(sum / readCount)
                        val volume = (rms * 4.0).coerceIn(0.0, 1.0)

                        // Generate mock frequency spread for equalizer
                        val mockBands = DoubleArray(16) { idx ->
                            val falloff = 1.0 - (idx * 0.04)
                            (volume * falloff).coerceIn(0.05, 1.0)
                        }

                        sendAudioEvent(volume, mockBands.toList(), volume)
                    }
                    try {
                        Thread.sleep(35)
                    } catch (_: InterruptedException) {
                        break
                    }
                }
            }
            Log.i("StripCtlAudio", "Mic capture successfully started")
            true
        } catch (e: Exception) {
            Log.e("StripCtlAudio", "Error starting AudioRecord", e)
            false
        }
    }

    private fun sendAudioEvent(energy: Double, bands: List<Double>?, bass: Double = energy) {
        val payload = HashMap<String, Any>()
        payload["energy"] = energy
        payload["bass"] = bass
        if (bands != null) {
            payload["bands"] = bands
        }
        mainHandler.post {
            eventSink?.success(payload)
        }
    }

    private fun stopAllAudio() {
        try {
            visualizer?.enabled = false
            visualizer?.release()
        } catch (e: Exception) {
            Log.w("StripCtlAudio", "Visualizer release error: ${e.message}")
        } finally {
            visualizer = null
        }

        isRecordingMic = false
        try {
            audioRecord?.stop()
            audioRecord?.release()
        } catch (e: Exception) {
            Log.w("StripCtlAudio", "AudioRecord release error: ${e.message}")
        } finally {
            audioRecord = null
        }
    }

    override fun onDestroy() {
        stopAllAudio()
        super.onDestroy()
    }
}

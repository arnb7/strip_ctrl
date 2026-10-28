# StripCtrl (`strip_ctrl`)

A high-performance, privacy-first Flutter controller for **ELK-BLEDOM** and **BLEDOM** Bluetooth Low Energy (BLE) RGB/RGBW LED strip lights.

---

## ⚡ Highlights

- **🔒 Zero Internet Permissions**: Built with pure local Bluetooth LE (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`, `RECORD_AUDIO`). Absolutely no `android.permission.INTERNET`. Zero telemetry, zero analytics, zero external network traffic.
- **🎨 Exact Hardware Pin-Order Remapping (`GRB`)**: Custom channel mapping for physical controllers labeled `OUTPUT: [ V+ | G | R | B ]`. Eliminates inverted Red/Green channels in hardware by driving Pin 2 (Green) and Pin 3 (Red) accurately, with one-tap `Test R`, `Test G`, `Test B` hardware verification and custom pin selection (`GRB`, `RGB`, `BRG`, `BGR`).
- **🎵 Internal Audio & Real-Time DSP Music Sync**:
  - Live capture using `noise_meter` / `record` streaming directly into a fast Fourier transform / bandpass DSP engine.
  - 4 customizable reactive visual modes: **Beat Pulse**, **Frequency Wave**, **Bass Drop**, and **Spectrum Dance**.
  - Configurable sensitivity, floor cutoff, and smoothing multipliers.
- **🌈 Pure HSV Radial Color Wheel & Color Temperature**:
  - High-precision dual-dimension HSV wheel supporting angular Hue ($0^\circ - 360^\circ$) and radial Saturation ($0.05 - 1.0$) with pastel-to-white blending.
  - Dedicated White CCT mode ($2700\text{K} - 6500\text{K}$) with white balance trims.
  - Quick-pick curated palettes and customizable preset slots.
- **✨ 29 Classic Dynamic Effects**: Complete BLEDOM effect catalog including Rainbow Fade, 7-Color Jump, Strobe, Crossfade, Pulse, and custom speed controls ($0 - 100\%$).
- **📱 Polished AMOLED Black, True `#000000` AMOLED background, bottom navigation tabs, fluid bounce scroll physics, hardware pin badges, and responsive layouts.
- **🔄 Robust Bluetooth Reconnection & Direct Frame Streaming**: Auto-discovery and quick-connect for devices (e.g. `BE:58:90:00:93:7B`), proactive connection recovery, and rate-limited command queuing.

---

## 🏗️ Architecture & Monorepo Structure

```
stripctl/
├── packages/
│   └── led_core/              # Pure Dart core engine (Zero Flutter dependencies)
│       ├── lib/
│       │   ├── src/
│       │   │   ├── codec/     # BLEDOM frame encoder/decoder & 25 section test vectors
│       │   │   ├── crypto/    # ELK-BLEDOM encryption & keystream generation
│       │   │   ├── models/    # DeviceState, ColorModel, EffectCatalog
│       │   │   └── scheduler/ # Low-latency BLE command coalescer & throttler
│       │   └── led_core.dart
│       └── test/              # 31 unit & protocol test vectors
├── app/                       # Flutter Material 3 / AMOLED Android App
│   ├── android/               # Android native configuration (Manifest & Gradle)
│   ├── assets/                # App icons & branding
│   ├── lib/
│   │   ├── main.dart          # Entrypoint & theme configuration
│   │   └── src/
│   │       ├── ble/           # flutter_blue_plus transport & auto-reconnect
│   │       ├── audio/         # Internal audio capture & real-time DSP visualizer
│   │       ├── providers/     # StateNotifier state management & persistent storage
│   │       └── ui/            # Screens (Control, Effects, Music, Devices, Diagnostics)
│   └── test/                  # Automated Flutter widget & UI tests
└── tool/
    └── check.sh               # CI validation script (formatting, analyze, tests)
```

---

## 🔬 Protocol & Pin Mapping Specification

### BLEDOM Protocol Framing
Commands follow an 8-to-9 byte framed structure:
- **Header**: `0x7E`
- **Length / Command Identifier**: e.g., `0x07 0x05 0x03` for RGB writes
- **Payload**: Color parameters `P1 P2 P3` (mapped according to physical pin order)
- **Trailer**: `0x10 0xEF` (or `0xFF 0x00 0xEF` for power state)

### Hardware Pin Order Remapping
Standard low-cost BLEDOM controllers use the following physical pin header:
```
INPUT:   [ V-  | V+ | VCC ]
OUTPUT:  [ V+  | G  | R  | B  ]
           Pin 1 Pin 2 Pin 3 Pin 4
```
Because the controller firmware maps protocol byte $P_1$ to Pin 2 (Green) and $P_2$ to Pin 3 (Red), transmitting naive RGB $(R, G, B)$ results in swapped red and green output.

StripCtrl uses a software remapping layer:
```dart
static (int, int, int) mapRgbForPinOrder(int r, int g, int b, String order) {
  switch (order) {
    case 'GRB': return (g, r, b); // P1=Green, P2=Red, P3=Blue
    case 'BRG': return (b, r, g);
    case 'BGR': return (b, g, r);
    case 'RGB':
    default:    return (r, g, b);
  }
}
```
`GRB` is set and persisted as the factory default, perfectly matching the controller's casing and providing accurate hardware colors out of the box.

---

## 🚀 Building & Running

### Prerequisites
- [Flutter SDK](https://flutter.dev) (v3.24+ recommended)
- [Android SDK](https://developer.android.com/studio) with Build-Tools 34+
- Java JDK 17+

### 1. Verification & Tests
Run static analysis, code formatting checks, and the full test suite across the monorepo:
```bash
bash tool/check.sh
```

### 2. Run in Debug Mode
Connect an Android device via ADB:
```bash
cd app
flutter run
```

### 3. Build Production APK
Build an optimized release APK:
```bash
cd app
flutter build apk --release
```
The compiled APK will be located at:
`app/build/app/outputs/flutter-apk/app-release.apk`

Verify permissions to confirm zero internet access:
```bash
aapt dump permissions build/app/outputs/flutter-apk/app-release.apk
```

---

## 📱 Permissions Breakdown

| Permission | Purpose |
| :--- | :--- |
| `BLUETOOTH_SCAN` | Locate nearby BLEDOM / ELK-BLEDOM LED strip controllers |
| `BLUETOOTH_CONNECT` | Establish GATT connection and send command frames |
| `RECORD_AUDIO` | Internal audio stream analysis for real-time music sync |
| `ACCESS_FINE_LOCATION` | Required on Android 11 and lower for BLE beacon scanning |
| **`INTERNET`** | **NONE** — Not requested, excluded from manifest |

---

## 📄 License
MIT License. Free to use, modify, and distribute.

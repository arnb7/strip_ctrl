class AppConstants {
  static const String appName = 'StripCtl';
  static const String serviceUuid = '0000fff0-0000-1000-8000-00805f9b34fb';
  static const String writeCharUuid = '0000fff3-0000-1000-8000-00805f9b34fb';

  static const List<String> scanPrefixes = <String>[
    'ELK',
    'BLEDOM',
    'MELK',
    'TRIONES',
    'LED LIGHT STRIP',
    'LED',
    'STRIP',
    'XSL',
    'DUOCO',
    'SP107',
  ];

  static const String encryptedMarker = 'ELK-*';

  static bool isSupportedDevice(String name) {
    final lower = name.trim().toLowerCase();
    if (lower.isEmpty) return false;
    for (final prefix in scanPrefixes) {
      if (lower.contains(prefix.toLowerCase())) return true;
    }
    return false;
  }

  static bool isEncryptedDevice(String name) {
    return name.contains(encryptedMarker);
  }
}

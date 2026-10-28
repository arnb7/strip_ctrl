import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PhotosensitivityHelper {
  static const _warnKey = 'stripctl_photosensitivity_acknowledged';

  static Future<bool> checkAndWarn(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    final acknowledged = prefs.getBool(_warnKey) ?? false;
    if (acknowledged) return true;

    if (!context.mounted) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded,
                color: Colors.amberAccent, size: 28),
            SizedBox(width: 10),
            Text('Safety Warning', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: const Text(
          'This mode produces rapid flashing and strobe patterns. '
          'Flashing lights can trigger seizures or disorientation in photosensitive individuals. '
          'Proceed with caution.',
          style: TextStyle(color: Colors.white70, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.amberAccent,
              foregroundColor: Colors.black,
            ),
            onPressed: () {
              prefs.setBool(_warnKey, true);
              Navigator.of(ctx).pop(true);
            },
            child: const Text('I Understand'),
          ),
        ],
      ),
    );

    return result ?? false;
  }
}

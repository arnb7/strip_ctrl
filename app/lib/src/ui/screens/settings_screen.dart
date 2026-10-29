import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/ui_style_provider.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _limitFlashing = true;
  bool _reduceMotion = false;
  bool _haptics = true;

  @override
  Widget build(BuildContext context) {
    final uiStyle = ref.watch(uiStyleProvider);

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        children: [
          // Appearance & UI Style
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              'Appearance & UI Style',
              style: TextStyle(
                color: Color(0xFFF97316),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SegmentedButton<UiStyle>(
              segments: const [
                ButtonSegment<UiStyle>(
                  value: UiStyle.workspace2,
                  icon: Icon(Icons.dashboard_customize_outlined),
                  label: Text('Workspace 2'),
                ),
                ButtonSegment<UiStyle>(
                  value: UiStyle.expressiveM3,
                  icon: Icon(Icons.palette_outlined),
                  label: Text('M3 Expressive'),
                ),
              ],
              selected: {uiStyle},
              onSelectionChanged: (Set<UiStyle> newSelection) {
                ref.read(uiStyleProvider.notifier).setStyle(newSelection.first);
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Switch between the classic compact Workspace 2 layout and the Google Material 3 Expressive squircle/pill design.',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),

          const Divider(height: 32),

          // Safety & Accessibility
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Safety & Accessibility',
              style: TextStyle(
                color: Color(0xFFF97316),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          SwitchListTile(
            title: const Text('Limit flashing to 3 Hz'),
            subtitle:
                const Text('Helps protect photosensitive users during strobes'),
            value: _limitFlashing,
            onChanged: (val) => setState(() => _limitFlashing = val),
          ),
          SwitchListTile(
            title: const Text('Reduce motion'),
            subtitle:
                const Text('Minimizes transitions and animated cross-fades'),
            value: _reduceMotion,
            onChanged: (val) => setState(() => _reduceMotion = val),
          ),
          SwitchListTile(
            title: const Text('Haptic feedback'),
            subtitle:
                const Text('Vibrate gently when selecting swatches and scenes'),
            value: _haptics,
            onChanged: (val) => setState(() => _haptics = val),
          ),

          const Divider(height: 32),

          // Privacy & Security Audit
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Text(
              'Privacy & Network Audit',
              style: TextStyle(
                color: Colors.deepOrangeAccent,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          const ListTile(
            leading: Icon(Icons.shield_outlined, color: Colors.greenAccent),
            title: Text('100% Offline App'),
            subtitle: Text(
              'Zero INTERNET permissions requested in release Android manifest or Flatpak manifest. '
              'Zero analytics. Zero telemetry.',
            ),
          ),
          const ListTile(
            leading: Icon(Icons.bluetooth, color: Colors.blueAccent),
            title: Text('Local BLE Only'),
            subtitle:
                Text('Controller MAC addresses never leave your local device.'),
          ),

          const Divider(height: 32),

          // Reset Data
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900),
              icon: const Icon(Icons.restore),
              label: const Text('Reset All Local Data & Scenes'),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Reset All Data?'),
                    content: const Text(
                        'This will reset saved scenes and cached device profiles.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red),
                        onPressed: () => Navigator.of(ctx).pop(true),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                );

                if (confirm == true) {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.clear();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('All local data cleared.')),
                    );
                  }
                }
              },
            ),
          ),

          const SizedBox(height: 36),

          // App identity & audit card
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFF141416),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF27272A)),
              ),
              child: const Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.bolt, size: 16, color: Color(0xFFF97316)),
                      SizedBox(width: 6),
                      Text(
                        'strip_ctrl',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFF4F4F5),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'v4 protocol',
                        style: TextStyle(fontSize: 11, color: Color(0xFFA1A1AA)),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    '100% offline · zero telemetry · zero internet permissions',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11, color: Color(0xFF71717A)),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

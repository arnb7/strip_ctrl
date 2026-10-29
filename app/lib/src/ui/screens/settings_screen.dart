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
              showSelectedIcon: false,
              segments: const [
                ButtonSegment<UiStyle>(
                  value: UiStyle.workspace2,
                  icon: Icon(Icons.dashboard_customize_outlined),
                  label: Text('Default'),
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
              'Switch between the classic compact Default AMOLED layout and the Google Material 3 Expressive squircle/pill design.',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),

          const SizedBox(height: 12),
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Icon(Icons.aspect_ratio_rounded, size: 16, color: Color(0xFFF97316)),
                SizedBox(width: 8),
                Text(
                  'Display & Text Scale (1080p Comfort)',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: Color(0xFFF4F4F5),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Consumer(
              builder: (context, ref, _) {
                final currentScale = ref.watch(desktopUiScaleProvider);
                return SegmentedButton<double>(
                  showSelectedIcon: false,
                  segments: const [
                    ButtonSegment<double>(
                      value: 1.0,
                      label: Text('1.0x (Compact)'),
                    ),
                    ButtonSegment<double>(
                      value: 1.15,
                      label: Text('1.15x (Standard)'),
                    ),
                    ButtonSegment<double>(
                      value: 1.22,
                      label: Text('1.22x (1080p Comfort)'),
                    ),
                    ButtonSegment<double>(
                      value: 1.35,
                      label: Text('1.35x (Large)'),
                    ),
                  ],
                  selected: {
                    if (currentScale <= 1.05)
                      1.0
                    else if (currentScale <= 1.18)
                      1.15
                    else if (currentScale <= 1.28)
                      1.22
                    else
                      1.35
                  },
                  onSelectionChanged: (Set<double> newSelection) {
                    ref
                        .read(desktopUiScaleProvider.notifier)
                        .setScale(newSelection.first);
                  },
                );
              },
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Text(
              'Adjusts typography, button targets, and visual comfort across 1080p displays.',
              style: TextStyle(fontSize: 12, color: Colors.white54),
            ),
          ),

          if (uiStyle == UiStyle.expressiveM3) ...[
            const SizedBox(height: 16),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Icon(Icons.color_lens_outlined, size: 16, color: Color(0xFFF97316)),
                  SizedBox(width: 8),
                  Text(
                    'Expressive Colorful Themes',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Color(0xFFF4F4F5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: M3ThemePreset.values.map((preset) {
                  final activePreset = ref.watch(m3ThemePresetProvider);
                  final isSelected = activePreset == preset;
                  final theme = Theme.of(context);

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: isSelected
                          ? preset.primary.withOpacity(0.18)
                          : theme.colorScheme.surfaceContainer,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: isSelected
                              ? preset.primary
                              : theme.colorScheme.outline.withOpacity(0.20),
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [preset.primary, preset.secondary, preset.tertiary],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: preset.primary.withOpacity(0.40),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Icon(preset.icon, color: Colors.white, size: 20),
                        ),
                        title: Text(
                          preset.title,
                          style: TextStyle(
                            fontWeight:
                                isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : const Color(0xFFF4F4F5),
                          ),
                        ),
                        subtitle: Text(
                          preset.description,
                          style: const TextStyle(fontSize: 12, color: Colors.white60),
                        ),
                        trailing: isSelected
                            ? Icon(Icons.check_circle, color: preset.primary, size: 22)
                            : null,
                        onTap: () {
                          ref.read(m3ThemePresetProvider.notifier).setPreset(preset);
                        },
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],

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

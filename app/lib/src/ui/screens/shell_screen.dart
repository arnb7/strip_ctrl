import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../providers/device_state_provider.dart';
import '../../providers/transport_provider.dart';
import '../../providers/ui_style_provider.dart';
import '../widgets/device_header.dart';
import '../widgets/strip_display.dart';
import 'control_screen.dart';
import 'devices_screen.dart';
import 'diagnostics_screen.dart';
import 'effects_screen.dart';
import 'music_screen.dart';
import 'scenes_screen.dart';
import 'settings_screen.dart';
import 'timers_screen.dart';

class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 0;
  bool _showStrip = true;
  bool _hasAttemptedAutoConnect = false;

  static const List<_TabItem> _tabs = [
    _TabItem(title: 'Control', icon: Icons.tune),
    _TabItem(title: 'Effects', icon: Icons.auto_awesome),
    _TabItem(title: 'Music', icon: Icons.waves),
    _TabItem(title: 'Scenes', icon: Icons.bookmark_outline),
    _TabItem(title: 'Timers', icon: Icons.alarm),
    _TabItem(title: 'Devices', icon: Icons.bluetooth),
    _TabItem(title: 'Diagnostics', icon: Icons.monitor_heart_outlined),
    _TabItem(title: 'Settings', icon: Icons.settings_outlined),
  ];

  final List<Widget> _screens = const [
    ControlScreen(),
    EffectsScreen(),
    MusicScreen(),
    ScenesScreen(),
    TimersScreen(),
    DevicesScreen(),
    DiagnosticsScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tryAutoConnect();
    });
  }

  Future<void> _tryAutoConnect() async {
    if (_hasAttemptedAutoConnect || !mounted) return;
    _hasAttemptedAutoConnect = true;

    final transport = ref.read(transportProvider);
    if (transport.currentState == TransportState.ready) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final targetMac = prefs.getString('last_connected_device') ?? 'BE:58:90:00:93:7B';

      // Attempt direct connection to last known device or default BLEDOM MAC
      await transport.connect(targetMac).timeout(const Duration(seconds: 4));
      if (mounted) {
        ref.read(deviceStateProvider.notifier).syncStripToApp();
      }
    } catch (_) {
      // Auto-connect failed or device out of range; user can use Devices tab
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiStyle = ref.watch(uiStyleProvider);
    final isExpressive = uiStyle == UiStyle.expressiveM3;

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        bottom: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1040),
            child: Column(
              children: [
                // Safe, unclipped Device Header
                DeviceHeader(
                  onOpenDevices: () => setState(() => _currentIndex = 5),
                  showStrip: _showStrip,
                  onToggleStrip: () => setState(() => _showStrip = !_showStrip),
                ),

                // Top Hero Virtual LED Strip (collapsible to maximize viewport)
                if (_showStrip) const StripDisplay(),

                // Horizontal Tab Navigation Strip
                Container(
                  height: isExpressive ? 56 : 50,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: isExpressive
                        ? colorScheme.surfaceContainer
                        : const Color(0xFF000000),
                    border: Border(
                      bottom: BorderSide(
                        color: isExpressive
                            ? colorScheme.primary.withOpacity(0.20)
                            : const Color(0xFF1E1E22),
                        width: 1,
                      ),
                    ),
                  ),
                  child: Center(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_tabs.length, (index) {
                          final tab = _tabs[index];
                          final isSelected = _currentIndex == index;

                          final borderRadius = isExpressive
                              ? BorderRadius.circular(20)
                              : BorderRadius.circular(10);

                          return Padding(
                            padding: EdgeInsets.only(
                              right: index == _tabs.length - 1
                                  ? 0
                                  : (isExpressive ? 10 : 6),
                            ),
                            child: Center(
                              child: InkWell(
                                onTap: () => setState(() => _currentIndex = index),
                                borderRadius: borderRadius,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutCubic,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: isExpressive ? 16 : 13,
                                    vertical: isExpressive ? 9 : 8,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? colorScheme.primary
                                        : (isExpressive
                                            ? colorScheme.surfaceContainerHigh
                                            : Colors.transparent),
                                    borderRadius: borderRadius,
                                    border: Border.all(
                                      color: isSelected
                                          ? colorScheme.primary
                                          : (isExpressive
                                              ? colorScheme.primary.withOpacity(0.25)
                                              : const Color(0xFF1E1E22)),
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        tab.icon,
                                        size: isExpressive ? 18 : 16,
                                        color: isSelected
                                            ? colorScheme.onPrimary
                                            : colorScheme.onSurface.withOpacity(0.65),
                                      ),
                                      const SizedBox(width: 7),
                                      Text(
                                        tab.title,
                                        style: TextStyle(
                                          fontSize: isExpressive ? 14 : 13,
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.w500,
                                          color: isSelected
                                              ? colorScheme.onPrimary
                                              : colorScheme.onSurface.withOpacity(0.70),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),
                ),

                // Main Active Tab Content
                Expanded(
                  child: IndexedStack(
                    index: _currentIndex,
                    children: _screens
                        .map((screen) => RepaintBoundary(child: screen))
                        .toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  final String title;
  final IconData icon;

  const _TabItem({required this.title, required this.icon});
}

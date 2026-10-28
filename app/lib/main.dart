import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/core/theme.dart';
import 'src/providers/device_state_provider.dart';
import 'src/providers/ui_style_provider.dart';
import 'src/ui/screens/onboarding_screen.dart';
import 'src/ui/screens/shell_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;

  runApp(
    ProviderScope(
      child: StripCtlApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}

class StripCtlApp extends ConsumerStatefulWidget {
  final bool showOnboarding;

  const StripCtlApp({super.key, required this.showOnboarding});

  @override
  ConsumerState<StripCtlApp> createState() => _StripCtlAppState();
}

class _StripCtlAppState extends ConsumerState<StripCtlApp> {
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _showOnboarding = widget.showOnboarding;
  }

  void _finishOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    setState(() {
      _showOnboarding = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deviceStateProvider);
    final uiStyle = ref.watch(uiStyleProvider);
    final accentColor = Color.fromARGB(255, state.r, state.g, state.b);

    return MaterialApp(
      title: 'StripCtl',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.amoledTheme(
        accentColor: state.power ? accentColor : Colors.deepOrangeAccent,
        style: uiStyle,
      ),
      home: _showOnboarding
          ? OnboardingScreen(onFinish: _finishOnboarding)
          : const ShellScreen(),
    );
  }
}

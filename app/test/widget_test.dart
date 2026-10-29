import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stripctl/main.dart';
import 'package:stripctl/src/providers/transport_provider.dart';
import 'package:stripctl/src/ui/widgets/hsv_color_wheel.dart';

void main() {
  testWidgets('StripCtlApp smoke test renders shell and control screen',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsProvider.overrideWith((ref) {
            final notifier = DiagnosticsNotifier();
            notifier.setUseFakeTransport(true);
            return notifier;
          }),
        ],
        child: const StripCtlApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Brightness'), findsOneWidget);
    expect(find.text('Color RGB'), findsOneWidget);
    expect(find.text('White CCT'), findsOneWidget);
    expect(find.text('Control'), findsWidgets);
    expect(find.text('Effects'), findsWidgets);
    expect(find.text('Scenes'), findsWidgets);
  });

  testWidgets('ControlScreen sliders and wheel respond to touch without error',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsProvider.overrideWith((ref) {
            final notifier = DiagnosticsNotifier();
            notifier.setUseFakeTransport(true);
            return notifier;
          }),
        ],
        child: const StripCtlApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    // Tap on Color Wheel
    final wheelFinder = find.byType(HsvColorWheel);
    expect(wheelFinder, findsOneWidget);
    await tester.tap(wheelFinder);
    await tester.pumpAndSettle();

    // Switch to Sliders tab
    await tester.tap(find.text('Sliders'));
    await tester.pumpAndSettle();

    // Verify Red, Green, Blue sliders exist
    expect(find.text('Red'), findsOneWidget);
    expect(find.text('Green'), findsOneWidget);
    expect(find.text('Blue'), findsOneWidget);

    // Tap Brightness +5% button
    final addIcon = find.byIcon(Icons.add);
    await tester.ensureVisible(addIcon);
    await tester.tap(addIcon);
    await tester.pumpAndSettle();

    // Switch to White CCT mode
    final whiteCctFinder = find.text('White CCT');
    await tester.ensureVisible(whiteCctFinder);
    await tester.tap(whiteCctFinder);
    await tester.pumpAndSettle();
    expect(find.text('Warm White'), findsOneWidget);
    expect(find.text('Cold White'), findsOneWidget);
  });

  testWidgets('DevicesScreen displays Quick Connect for BE:58:90:00:93:7B',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsProvider.overrideWith((ref) {
            final notifier = DiagnosticsNotifier();
            notifier.setUseFakeTransport(true);
            return notifier;
          }),
        ],
        child: const StripCtlApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Devices in the header
    final headerFinder = find.textContaining('No Device');
    if (headerFinder.evaluate().isNotEmpty) {
      await tester.tap(headerFinder.first);
      await tester.pumpAndSettle();
    }

    // Verify Quick Connect button exists
    expect(find.text('Quick Connect: BE:58:90:00:93:7B'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, -300));
    await tester.pumpAndSettle();

    final wizardFinder = find.text('Terminal Pin Order (Hardware Wizard)');
    expect(wizardFinder, findsOneWidget);
  });

  testWidgets('MusicScreen renders spectrum visualizer and reactive presets',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsProvider.overrideWith((ref) {
            final notifier = DiagnosticsNotifier();
            notifier.setUseFakeTransport(true);
            return notifier;
          }),
        ],
        child: const StripCtlApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Music tab in bottom nav
    await tester.tap(find.text('Music'));
    await tester.pumpAndSettle();

    expect(find.text('Music Reactive Mode'), findsOneWidget);
    expect(find.text('Sensitivity'), findsOneWidget);
    expect(find.text('Start Music Reactivity'), findsOneWidget);
    expect(find.text('Rainbow'), findsOneWidget);
    expect(find.text('Beat Flash'), findsOneWidget);
    expect(find.text('Ocean Blue'), findsOneWidget);
  });

  testWidgets(
      'DiagnosticsScreen displays Protocol Verification and runs 25 vectors',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsProvider.overrideWith((ref) {
            final notifier = DiagnosticsNotifier();
            notifier.setUseFakeTransport(true);
            return notifier;
          }),
        ],
        child: const StripCtlApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Diagnostics tab
    final diagFinder = find.text('Diagnostics');
    await tester.ensureVisible(diagFinder);
    await tester.tap(diagFinder);
    await tester.pumpAndSettle();

    expect(find.text('Protocol Verification'), findsOneWidget);
    final runButton = find.text('Run 25 Vectors');
    expect(runButton, findsOneWidget);

    await tester.tap(runButton);
    await tester.pumpAndSettle();

    expect(find.text('Protocol Verification Report'), findsOneWidget);
    expect(find.text('25/25 checks passed'), findsOneWidget);
  });

  testWidgets(
      'SettingsScreen displays Default style and reveals M3 colorful presets on toggle',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsProvider.overrideWith((ref) {
            final notifier = DiagnosticsNotifier();
            notifier.setUseFakeTransport(true);
            return notifier;
          }),
        ],
        child: const StripCtlApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    // Tap Settings tab
    final settingsFinder = find.text('Settings');
    await tester.ensureVisible(settingsFinder);
    await tester.tap(settingsFinder);
    await tester.pumpAndSettle();

    // Verify Default and M3 Expressive segments
    expect(find.text('Default'), findsOneWidget);
    expect(find.text('M3 Expressive'), findsOneWidget);

    // Switch to M3 Expressive
    await tester.tap(find.text('M3 Expressive'));
    await tester.pumpAndSettle();

    // Verify Expressive Colorful Themes section and presets are revealed
    expect(find.text('Expressive Colorful Themes'), findsOneWidget);
    expect(find.text('System Monet'), findsOneWidget);
    expect(find.text('Electric Violet'), findsOneWidget);
    expect(find.text('Sunset Blaze'), findsOneWidget);

    // Tap Electric Violet preset
    await tester.tap(find.text('Electric Violet'));
    await tester.pumpAndSettle();
  });

  testWidgets(
      'ControlScreen renders 24 centered vibrant LED swatches without unsupported brown/grey',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          diagnosticsProvider.overrideWith((ref) {
            final notifier = DiagnosticsNotifier();
            notifier.setUseFakeTransport(true);
            return notifier;
          }),
        ],
        child: const StripCtlApp(showOnboarding: false),
      ),
    );

    await tester.pumpAndSettle();

    // Verify exactly 24 color swatch inkwells in control screen
    final swatchInkWells = find.byWidgetPredicate((widget) {
      return widget is AnimatedContainer &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).shape == BoxShape.circle &&
          (widget.constraints?.maxWidth == 36 || widget.constraints?.minWidth == 36);
    });
    expect(swatchInkWells, findsNWidgets(24));

    // Scroll to make swatches visible
    await tester.ensureVisible(swatchInkWells.first);
    await tester.pumpAndSettle();

    // Tap on the first swatch (Pure Red: 0xFFFF0000)
    await tester.tap(swatchInkWells.first);
    await tester.pumpAndSettle();
    expect(find.text('#FF0000'), findsOneWidget);

    // Tap on Cyan swatch (#00FFFF)
    final cyanFinder = find.byWidgetPredicate((widget) {
      if (widget is AnimatedContainer && widget.decoration is BoxDecoration) {
        final box = widget.decoration as BoxDecoration;
        return box.color == const Color(0xFF00FFFF);
      }
      return false;
    });
    expect(cyanFinder, findsOneWidget);
    await tester.ensureVisible(cyanFinder);
    await tester.pumpAndSettle();
    await tester.tap(cyanFinder);
    await tester.pumpAndSettle();
    expect(find.text('#00FFFF'), findsOneWidget);
  });
}

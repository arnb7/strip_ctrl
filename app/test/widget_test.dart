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
}

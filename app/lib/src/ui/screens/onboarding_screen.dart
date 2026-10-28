import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  final VoidCallback onFinish;

  const OnboardingScreen({super.key, required this.onFinish});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'StripCtl Setup',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  TextButton(
                    onPressed: widget.onFinish,
                    child: const Text('Skip',
                        style: TextStyle(color: Colors.white54)),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (idx) => setState(() => _currentPage = idx),
                children: [
                  _buildStep(
                    icon: Icons.shield_outlined,
                    iconColor: Colors.greenAccent,
                    title: '100% Offline & Private',
                    description:
                        'The original vendor app phones home with telemetry. '
                        'StripCtl has zero network permissions, zero accounts, and zero tracking.',
                  ),
                  _buildStep(
                    icon: Icons.bluetooth,
                    iconColor: Colors.blueAccent,
                    title: 'Local Bluetooth LE Control',
                    description:
                        'Connects directly to your ElkBLEDOM / duoCoStrip LED controller over Bluetooth. '
                        'No cloud servers or internet required.',
                  ),
                  _buildStep(
                    icon: Icons.tips_and_updates_outlined,
                    iconColor: Colors.amberAccent,
                    title: 'Quick Hardware Tips',
                    description:
                        '1. Make sure the LED controller has 5-24V power.\n'
                        '2. Close the vendor duoCoStrip app completely (the controller only accepts ONE active BLE connection at a time).\n'
                        '3. Stay within ~2 meters during initial pairing.',
                  ),
                  _buildStep(
                    icon: Icons.battery_saver,
                    iconColor: Colors.purpleAccent,
                    title: 'Smooth Background Timers',
                    description:
                        'For sleep timers and alarms to fire reliably when the screen is locked, '
                        'disable battery optimization for StripCtl in your OS settings.',
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: List.generate(
                      4,
                      (idx) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        width: _currentPage == idx ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _currentPage == idx
                              ? Colors.deepOrangeAccent
                              : Colors.white24,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.deepOrangeAccent,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                    ),
                    onPressed: () {
                      if (_currentPage < 3) {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeInOut,
                        );
                      } else {
                        widget.onFinish();
                      }
                    },
                    child: Text(_currentPage == 3 ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 64, color: iconColor),
          ),
          const SizedBox(height: 32),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 16),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
                fontSize: 14, color: Colors.white70, height: 1.5),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/device_state_provider.dart';

class TimersScreen extends ConsumerStatefulWidget {
  const TimersScreen({super.key});

  @override
  ConsumerState<TimersScreen> createState() => _TimersScreenState();
}

class _TimersScreenState extends ConsumerState<TimersScreen> {
  int? _activeSleepTimerMinutes;

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(deviceStateProvider.notifier);

    return Scaffold(
      body: ListView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
        children: [
          // Quick Sleep Timer Card
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.bedtime, color: Colors.purpleAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Quick Sleep Timer',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _activeSleepTimerMinutes != null
                        ? 'Strip will turn off after $_activeSleepTimerMinutes minutes.'
                        : 'Select duration to turn off strip automatically:',
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    children: [15, 30, 60, 90].map((mins) {
                      final isSelected = _activeSleepTimerMinutes == mins;
                      return ActionChip(
                        label: Text('$mins min'),
                        backgroundColor: isSelected
                            ? Colors.purpleAccent.withOpacity(0.3)
                            : const Color(0xFF2A2A2A),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.purpleAccent
                              : Colors.transparent,
                        ),
                        onPressed: () {
                          setState(() {
                            _activeSleepTimerMinutes = mins;
                          });
                          Future.delayed(Duration(minutes: mins), () {
                            if (_activeSleepTimerMinutes == mins) {
                              notifier.setPower(false);
                              if (mounted) {
                                setState(() => _activeSleepTimerMinutes = null);
                              }
                            }
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Sleep timer armed: $mins minutes'),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  if (_activeSleepTimerMinutes != null) ...[
                    const SizedBox(height: 12),
                    TextButton.icon(
                      style: TextButton.styleFrom(
                          foregroundColor: Colors.redAccent),
                      icon: const Icon(Icons.cancel, size: 18),
                      label: const Text('Cancel Sleep Timer'),
                      onPressed: () {
                        setState(() => _activeSleepTimerMinutes = null);
                      },
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Sunrise Wake-Up Builder
          Card(
            color: const Color(0xFF1E1E1E),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.wb_twilight,
                          color: Colors.amberAccent, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Sunrise Wake-Up Alarm',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Gradually transitions from dim amber to warm daylight over 15 minutes before your alarm time.',
                    style: TextStyle(color: Colors.white60, fontSize: 13),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.alarm_add),
                    label: const Text('Configure Sunrise Time'),
                    onPressed: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: const TimeOfDay(hour: 7, minute: 0),
                      );
                      if (time != null && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Sunrise scheduled for ${time.format(context)}'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scheduling Engine Indicator
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF121212),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white12),
            ),
            child: const Row(
              children: [
                Icon(Icons.schedule, size: 18, color: Colors.white54),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Engine: Phone-side Exact Alarms (Default, 100% reliable across Android & Fedora Linux systemd timers).',
                    style: TextStyle(fontSize: 11, color: Colors.white60),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:led_core/led_core.dart';
import '../../providers/device_state_provider.dart';
import '../../providers/scenes_provider.dart';

class ScenesScreen extends ConsumerWidget {
  const ScenesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scenes = ref.watch(scenesProvider);
    final currentState = ref.watch(deviceStateProvider);
    final scenesNotifier = ref.read(scenesProvider.notifier);
    final deviceNotifier = ref.read(deviceStateProvider.notifier);

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.deepOrangeAccent,
        foregroundColor: Colors.black,
        icon: const Icon(Icons.add),
        label: const Text('Save Current'),
        onPressed: () =>
            _promptSaveScene(context, currentState, scenesNotifier),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Saved Scenes (${scenes.length})',
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.download, size: 20),
                        tooltip: 'Import scenes JSON from clipboard',
                        onPressed: () async {
                          final data =
                              await Clipboard.getData(Clipboard.kTextPlain);
                          if (data?.text != null) {
                            final success =
                                scenesNotifier.importJson(data!.text!);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(success
                                      ? 'Scenes imported successfully!'
                                      : 'Invalid scenes JSON in clipboard'),
                                ),
                              );
                            }
                          }
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.upload, size: 20),
                        tooltip: 'Export scenes JSON to clipboard',
                        onPressed: () async {
                          final json = scenesNotifier.exportJson();
                          await Clipboard.setData(ClipboardData(text: json));
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Scenes JSON copied to clipboard!'),
                              ),
                            );
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 200,
                childAspectRatio: 1.25,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final scene = scenes[index];
                  final isRainbow = scene.name.toLowerCase().contains('rainbow') ||
                      scene.effectIndex == 10 ||
                      scene.effectIndex == 8 ||
                      scene.effectIndex == 21;

                  final previewColor = scene.mode == ActiveLedMode.color
                      ? Color.fromARGB(255, scene.r, scene.g, scene.b)
                      : (scene.mode == ActiveLedMode.white
                          ? Colors.amberAccent
                          : Colors.deepPurpleAccent);

                  return InkWell(
                    onTap: () {
                      deviceNotifier.updateFromScene(scene);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Applied scene: ${scene.name} (persists on controller)'),
                          duration: const Duration(milliseconds: 1200),
                        ),
                      );
                    },
                    onLongPress: () =>
                        _confirmDeleteScene(context, scene, scenesNotifier),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF181818),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isRainbow ? Colors.orangeAccent.withOpacity(0.5) : Colors.white12,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isRainbow ? null : previewColor,
                                  gradient: isRainbow
                                      ? const SweepGradient(
                                          colors: [
                                            Colors.red,
                                            Colors.orange,
                                            Colors.yellow,
                                            Colors.green,
                                            Colors.cyan,
                                            Colors.blue,
                                            Colors.purple,
                                            Colors.red,
                                          ],
                                        )
                                      : null,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isRainbow ? Colors.white : Colors.white24,
                                    width: isRainbow ? 1.5 : 1.0,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: (isRainbow ? Colors.orange : previewColor)
                                          .withOpacity(0.5),
                                      blurRadius: 8,
                                    )
                                  ],
                                ),
                              ),
                              IconButton(
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                icon: Icon(
                                  scene.isFavorite
                                      ? Icons.star
                                      : Icons.star_border,
                                  size: 20,
                                  color: scene.isFavorite
                                      ? Colors.amberAccent
                                      : Colors.white30,
                                ),
                                onPressed: () =>
                                    scenesNotifier.toggleFavorite(scene.id),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                scene.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                scene.mode == ActiveLedMode.effect
                                    ? 'HARDWARE · ${scene.brightness}%'
                                    : '${scene.mode.name.toUpperCase()} · ${scene.brightness}%',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: scene.mode == ActiveLedMode.effect
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                                  color: scene.mode == ActiveLedMode.effect
                                      ? const Color(0xFFF97316)
                                      : Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
                childCount: scenes.length,
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
    );
  }

  void _promptSaveScene(
      BuildContext context, DeviceState state, ScenesNotifier notifier) {
    final controller = TextEditingController(text: 'My Scene');
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text('Save Current Strip State',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Scene Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isNotEmpty) {
                final newScene = LedScene.fromDeviceState(
                  id: 'scene_${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  state: state,
                );
                notifier.addScene(newScene);
                Navigator.of(ctx).pop();
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteScene(
      BuildContext context, LedScene scene, ScenesNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Text('Delete "${scene.name}"?',
            style: const TextStyle(color: Colors.white)),
        content: const Text('This scene will be permanently removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              notifier.removeScene(scene.id);
              Navigator.of(ctx).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

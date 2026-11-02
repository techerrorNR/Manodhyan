import 'package:flutter/material.dart';
import '../mind/config/app_palette.dart';
import '../services/floating_focus_service.dart';

class FloatingFocusSettings extends StatefulWidget {
  const FloatingFocusSettings({super.key});
  @override
  State<FloatingFocusSettings> createState() => _FloatingFocusSettingsState();
}

class _FloatingFocusSettingsState extends State<FloatingFocusSettings> {
  final _shortcut = FloatingFocusService.instance;
  bool _busy = false;

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Unable to save shortcut settings. Please retry.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _shortcut,
    builder:
        (context, _) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppPalette.card,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Floating Focus button'),
                subtitle: Text(
                  _shortcut.isAndroid
                      ? 'Drag it anywhere, even over other apps.'
                      : 'Drag the shortcut anywhere inside FocusJoy.',
                ),
                value: _shortcut.enabled,
                onChanged:
                    _busy
                        ? null
                        : (value) => _run(() => _shortcut.setEnabled(value)),
              ),
              if (_shortcut.enabled &&
                  _shortcut.isAndroid &&
                  !_shortcut.permission)
                TextButton.icon(
                  onPressed:
                      _busy ? null : () => _run(_shortcut.requestPermission),
                  icon: const Icon(Icons.layers_outlined),
                  label: const Text('Allow display over other apps'),
                ),
              if (_shortcut.enabled && _shortcut.error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    _shortcut.error!,
                    style: const TextStyle(
                      color: AppPalette.secondary,
                      height: 1.5,
                    ),
                  ),
                ),
              if (_shortcut.enabled)
                TextButton.icon(
                  onPressed:
                      _busy
                          ? null
                          : () => _run(() => _shortcut.savePosition(1, 0.5)),
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Reset position'),
                ),
            ],
          ),
        ),
  );
}

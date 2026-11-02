import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coordinates the native overlay and the draggable Flutter fallback.
class FloatingFocusService extends ChangeNotifier {
  FloatingFocusService({MethodChannel? channel, bool? android})
    : _channel = channel ?? const MethodChannel('focusjoy/floating_focus'),
      isAndroid =
          android ??
          (!kIsWeb && defaultTargetPlatform == TargetPlatform.android);

  static final instance = FloatingFocusService();
  final MethodChannel _channel;
  final bool isAndroid;
  bool enabled = true;
  bool permission = false;
  bool running = false;
  bool pendingOpenFocus = false;
  double x = 1;
  double y = 0.5;
  String? error;
  bool get usesNativeOverlay => enabled && isAndroid && permission && running;
  static const _enabledKey = 'focusjoy_floating_focus_enabled';
  static const _xKey = 'focusjoy_floating_focus_x';
  static const _yKey = 'focusjoy_floating_focus_y';

  static double _fraction(num? value, double fallback) =>
      value != null && value.isFinite ? value.toDouble().clamp(0, 1) : fallback;

  Future<void> initialize() async {
    if (isAndroid) {
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'stateChanged') _apply(call.arguments);
      });
    }
    await refresh();
  }

  void _apply(dynamic raw) {
    if (raw is! Map) return;
    enabled = raw['enabled'] as bool? ?? true;
    permission = raw['permission'] as bool? ?? false;
    running = raw['running'] as bool? ?? false;
    x = _fraction(raw['x'] as num?, 1);
    y = _fraction(raw['y'] as num?, 0.5);
    pendingOpenFocus = pendingOpenFocus || raw['openFocusRequested'] == true;
    error = raw['error'] as String?;
    notifyListeners();
  }

  Future<void> refresh() async {
    if (isAndroid) {
      try {
        _apply(await _channel.invokeMethod('getState'));
      } on PlatformException catch (_) {
        error = 'Unable to read the floating shortcut settings. Please retry.';
        notifyListeners();
      } on MissingPluginException catch (_) {
        /* Keep the in-app fallback available. */
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      enabled = prefs.getBool(_enabledKey) ?? true;
      x = _fraction(prefs.getDouble(_xKey), 1);
      y = _fraction(prefs.getDouble(_yKey), 0.5);
      notifyListeners();
    }
  }

  Future<void> setEnabled(bool value) async {
    if (isAndroid) {
      try {
        _apply(await _channel.invokeMethod('setEnabled', {'enabled': value}));
        if (value && !permission) await requestPermission();
      } on PlatformException catch (_) {
        error = 'Unable to update the floating shortcut. Please retry.';
        notifyListeners();
      } on MissingPluginException catch (_) {
        _missingNativeSupport();
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setBool(_enabledKey, value)) {
        throw StateError('Unable to save shortcut settings');
      }
      enabled = value;
      notifyListeners();
    }
  }

  Future<void> requestPermission() async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('requestPermission');
    } on PlatformException catch (_) {
      error =
          'Open Android Settings → Display over other apps → FocusJoy and allow it.';
      notifyListeners();
    } on MissingPluginException catch (_) {
      _missingNativeSupport();
    }
  }

  void previewPosition(double nextX, double nextY) {
    x = _fraction(nextX, x);
    y = _fraction(nextY, y);
    notifyListeners();
  }

  Future<void> savePosition(double nextX, double nextY) async {
    previewPosition(nextX, nextY);
    if (isAndroid) {
      try {
        _apply(await _channel.invokeMethod('setPosition', {'x': x, 'y': y}));
      } on PlatformException catch (_) {
        error = 'The shortcut position could not be saved. Please retry.';
        notifyListeners();
      } on MissingPluginException catch (_) {
        _missingNativeSupport();
      }
    } else {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setDouble(_xKey, x) ||
          !await prefs.setDouble(_yKey, y)) {
        error = 'The shortcut position could not be saved. Please retry.';
        notifyListeners();
      }
    }
  }

  Future<void> setInAppVisible(bool visible) async {
    if (!isAndroid) return;
    try {
      await _channel.invokeMethod('setInAppVisible', visible);
    } on PlatformException catch (_) {
      /* A service refresh on resume will retry. */
    } on MissingPluginException catch (_) {
      /* Flutter fallback remains available. */
    }
  }

  Future<void> consumeFocusRequest() async {
    pendingOpenFocus = false;
    if (isAndroid) {
      try {
        await _channel.invokeMethod('consumeFocusRequest');
      } on PlatformException catch (_) {
        /* The next state refresh can retry. */
      } on MissingPluginException catch (_) {
        _missingNativeSupport();
      }
    }
    pendingOpenFocus = false;
    notifyListeners();
  }

  void _missingNativeSupport() {
    error = 'Restart FocusJoy after installing the updated Android app.';
    notifyListeners();
  }

  @override
  void dispose() {
    if (isAndroid) _channel.setMethodCallHandler(null);
    super.dispose();
  }
}

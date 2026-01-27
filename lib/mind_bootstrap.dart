import 'package:flutter/foundation.dart';
import 'package:manodhyan/mind/core/services/drift_db_service.dart';
import 'package:manodhyan/mind/core/services/method_channel_service.dart';

/// Boots ManoDhyan's platform stack (method channel + Drift DB) once so its
/// modules can run safely inside ManoDhyan.
class ManoDhyanBootstrap {
  ManoDhyanBootstrap._();

  static final ManoDhyanBootstrap instance = ManoDhyanBootstrap._();

  bool _initialized = false;
  Future<void>? _pending;

  Future<void> ensureInitialized() async {
    if (_initialized) return;
    if (_pending != null) {
      await _pending;
      return;
    }

    final future = _bootstrap();
    _pending = future;
    await future;
    _pending = null;
    _initialized = true;
  }

  Future<void> _bootstrap() async {
    try {
      await MethodChannelService.instance.init();
      await DriftDbService.instance.init();
    } catch (err) {
      debugPrint('ManoDhyanBootstrap: $err');
    }
  }
}

import 'package:device_installed_apps/app_info.dart' as device_apps;
import 'package:device_installed_apps/device_installed_apps.dart';
import 'package:flutter/foundation.dart';
import 'package:manodhyan/mind/models/app_info.dart';

class AppNameResolver {
  static final Map<String, String> _cachedNames = {};
  static List<device_apps.AppInfo>? _allApps;

  static Future<void> _loadApps() async {
    _allApps ??= await DeviceInstalledApps.getApps(
      includeSystemApps: true,
      includeIcon: true,
      permissions: [],
      shouldHasAllPermissions: false,
    );
  }

  static device_apps.AppInfo? _findApp(String packageName) {
    final apps = _allApps;
    if (apps == null) return null;
    for (final app in apps) {
      if (app.bundleId == packageName) {
        return app;
      }
    }
    return null;
  }

  static Future<AppInfo?> getAppInfo(String packageName) async {
    await _loadApps();
    final deviceApp = _findApp(packageName);
    
    if (deviceApp == null) return null;

    return AppInfo(
      name: deviceApp.name ?? packageName,
      packageName: deviceApp.bundleId ?? packageName,
      isImpSysApp: false, // Defaulting, as logic for this isn't in device_apps
      icon: deviceApp.icon ?? Uint8List(0),
    );
  }

  static Future<String> getAppName(String packageName) async {
    await _loadApps();

    final cached = _cachedNames[packageName];
    if (cached != null) {
      return cached;
    }

    final app = _findApp(packageName);
    final appName = app?.name ?? packageName;
    _cachedNames[packageName] = appName;
    return appName;
  }

  static Future<Map<String, String>> resolveNames(List<String> packageNames) async {
    await _loadApps();

    final Map<String, String> result = {};
    for (final pkg in packageNames) {
      final app = _findApp(pkg);
      final appName = app?.name ?? pkg;
      result[pkg] = appName;
      _cachedNames[pkg] = appName;
    }

    return result;
  }
}

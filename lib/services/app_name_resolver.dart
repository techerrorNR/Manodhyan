import 'package:device_installed_apps/app_info.dart';
import 'package:device_installed_apps/device_installed_apps.dart';

class AppNameResolver {
  static final Map<String, String> _cachedNames = {};
  static List<AppInfo>? _allApps;

  static Future<void> _loadApps() async {
    _allApps ??= await DeviceInstalledApps.getApps(
      includeSystemApps: true,
      includeIcon: false,
      permissions: [],
      shouldHasAllPermissions: false,
    );
  }

  static AppInfo? _findApp(String packageName) {
    final apps = _allApps;
    if (apps == null) return null;
    for (final app in apps) {
      if (app.bundleId == packageName) {
        return app;
      }
    }
    return null;
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

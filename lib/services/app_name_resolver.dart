import 'package:device_installed_apps/app_info.dart';
import 'package:device_installed_apps/device_installed_apps.dart';

class AppNameResolver {
  static final Map<String, String> _cachedNames = {};
  static List<AppInfo>? _allApps;

  static Future<void> _loadApps() async {
    if (_allApps == null) {
      _allApps = await DeviceInstalledApps.getApps(
        includeSystemApps: true,
        includeIcon: false,
        permissions: [],
        shouldHasAllPermissions: false,
      );
    }
  }

  static Future<String> getAppName(String packageName) async {
    await _loadApps();

    if (_cachedNames.containsKey(packageName)) {
      return _cachedNames[packageName]!;
    }

    try {
      final app = _allApps!.firstWhere(
            (app) => app.id == packageName,
        orElse: () => AppInfo(packageName, packageName), // ✅ Uses positional constructor
      );

      final appName = app.name ?? packageName;
      _cachedNames[packageName] = appName;
      return appName;
    } catch (e) {
      return packageName;
    }
  }

  static Future<Map<String, String>> resolveNames(List<String> packageNames) async {
    await _loadApps();

    final Map<String, String> result = {};
    for (final pkg in packageNames) {
      final app = _allApps!.firstWhere(
            (a) => a.id == pkg,
        orElse: () => AppInfo(pkg, pkg), // ✅ Fallback with positional args
      );
      final appName = app.name ?? pkg;
      result[pkg] = appName;
      _cachedNames[pkg] = appName;
    }

    return result;
  }
}

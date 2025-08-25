import 'package:firebase_remote_config/firebase_remote_config.dart';

class AdminConfig {
  // Static fallback for the functions base URL. If empty, Remote Config will be used.
  static const String _staticFunctionsBase = '';

  // Developer convenience flags
  static const bool forceEnableAdminUi = false;
  static const bool allowAdminInDebug = true;

  // Remote Config key to store the functions base URL
  static const String _rcKeyFunctionsBase = 'admin_functions_base_url';

  // Returns the functions base URL. If Remote Config has a value, it will be used,
  // otherwise the static fallback is returned.
  static Future<String> functionsBaseUrl() async {
    try {
      final rc = FirebaseRemoteConfig.instance;
      await rc.fetchAndActivate();
      final v = rc.getString(_rcKeyFunctionsBase);
      if (v.isNotEmpty) return v;
    } catch (_) {}
    return _staticFunctionsBase;
  }
}

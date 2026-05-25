import 'package:shared_preferences/shared_preferences.dart';

class AdminSession {
  static const String _isLoggedInKey = 'admin_is_logged_in';
  static const String _documentIdKey = 'admin_document_id';

  const AdminSession._();

  static Future<void> save({required String adminDocumentId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, true);
    await prefs.setString(_documentIdKey, adminDocumentId);
  }

  static Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  static Future<String?> getAdminDocumentId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_documentIdKey);
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_isLoggedInKey);
    await prefs.remove(_documentIdKey);
  }
}

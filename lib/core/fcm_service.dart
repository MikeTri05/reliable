import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class FCMService {
  // 👇 FUNGSI UNTUK MENEMBAKKAN NOTIFIKASI 👇
  static Future<void> sendPushNotification(
      String fcmToken, String title, String body) async {
    try {
      // 1. Baca file JSON Kunci Master
      final String jsonString =
          await rootBundle.loadString('assets/service_account.json');
      final credentials = ServiceAccountCredentials.fromJson(jsonString);

      // Ambil ID Proyek otomatis dari dalam file JSON
      final String projectId = jsonDecode(jsonString)['project_id'];

      // 2. Minta Izin (Token Akses) ke Google
      final scopes = ['https://www.googleapis.com/auth/firebase.messaging'];
      final client = await clientViaServiceAccount(credentials, scopes);
      final accessToken = client.credentials.accessToken.data;

      // 3. Rakit Pelurunya (Format API HTTP v1 terbaru)
      final String endpoint =
          'https://fcm.googleapis.com/v1/projects/$projectId/messages:send';
      final Map<String, dynamic> message = {
        'message': {
          'token': fcmToken, // <== Target HP
          'notification': {
            'title': title,
            'body': body,
          },
        }
      };

      // 4. TEMBAKKAN! 🚀
      final response = await http.post(
        Uri.parse(endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(message),
      );

      if (response.statusCode == 200) {
        print('✅ Sukses menembak notifikasi ke: $fcmToken');
      } else {
        print('❌ Gagal menembak: ${response.body}');
      }
    } catch (e) {
      print('❌ Error Mesin FCM: $e');
    }
  }
}

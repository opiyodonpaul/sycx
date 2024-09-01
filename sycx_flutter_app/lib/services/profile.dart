import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class ProfileService {
  static const _baseUrl = 'https://sycx-production.up.railway.app';

  static Future<bool> updateProfile(
      String userId, String username, String email, String profilePic) async {
    final token = await SecureStorage.getToken();
    final response = await http.put(
      Uri.parse('$_baseUrl/update_profile'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json'
      },
      body: jsonEncode({
        'user_id': userId,
        'username': username,
        'email': email,
        'profile_pic': profilePic
      }),
    );

    return response.statusCode == 200;
  }

  static Future<bool> deleteAccount(String userId) async {
    final token = await SecureStorage.getToken();
    final response = await http.delete(
      Uri.parse('$_baseUrl/delete_account?user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    return response.statusCode == 200;
  }

  static Future<Map<String, dynamic>> getUserProfile(String userId) async {
    final token = await SecureStorage.getToken();
    final response = await http.get(
      Uri.parse('$_baseUrl/user_profile?user_id=$userId'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile');
    }
  }
}

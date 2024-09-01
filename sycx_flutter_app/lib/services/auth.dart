import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class Auth {
  static const _baseUrl = 'https://your-api-url.com';

  static Future<bool> login(String email, String password) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    if (response.statusCode == 200) {
      await SecureStorage.saveToken(jsonDecode(response.body)['token']);
      return true;
    }
    return false;
  }

  static Future<bool> register(
      String username, String email, String password, String profilePic) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'profile_pic': profilePic
      }),
    );

    if (response.statusCode == 200) {
      await SecureStorage.saveToken(jsonDecode(response.body)['token']);
      return true;
    }
    return false;
  }

  static Future<bool> resetPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email}),
    );

    return response.statusCode == 200;
  }

  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}

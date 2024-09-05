import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class Auth {
  static final ApiClient _apiClient = ApiClient(httpClient: http.Client());

  static Future<bool> login(String username, String password) async {
    final response = await _apiClient.post(
      '/login',
      body: {'username': username, 'password': password},
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await SecureStorage.saveToken(responseData['user_id']);
      return true;
    }
    return false;
  }

  static Future<bool> register(
      String username, String email, String password, String profilePic) async {
    final response = await _apiClient.post(
      '/register',
      body: {
        'username': username,
        'email': email,
        'password': password,
        'profile_pic': profilePic
      },
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await SecureStorage.saveToken(responseData['user_id']);
      return true;
    }
    return false;
  }

  static Future<bool> resetPassword(String email) async {
    final response = await _apiClient.post(
      '/forgot_password',
      body: {'email': email},
    );

    return response.statusCode == 200;
  }

  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}

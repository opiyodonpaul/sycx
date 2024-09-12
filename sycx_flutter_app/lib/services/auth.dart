import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';

class Auth {
  static final ApiClient _apiClient = ApiClient(httpClient: http.Client());

  static Future<bool> login(String username, String password) async {
    final response = await _apiClient.post(
      '/login',
      body: jsonEncode({'username': username, 'password': password}),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await SecureStorage.saveToken(responseData['user_id']);
      return true;
    }
    return false;
  }

  static Future<bool> register(String fullname, String username, String email,
      String password, String profilePic) async {
    final response = await _apiClient.post(
      '/register',
      body: jsonEncode({
        'fullname': fullname,
        'username': username,
        'email': email,
        'password': password,
        'profile_pic': profilePic
      }),
      headers: {'Content-Type': 'application/json'},
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      await SecureStorage.saveToken(responseData['user_id']);
      return true;
    }
    return false;
  }

  static Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return false;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final response = await _apiClient.post(
        '/google_sign_in',
        body: jsonEncode({
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await SecureStorage.saveToken(responseData['user_id']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error during Google sign-in: $e');
      return false;
    }
  }

  static Future<bool> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await _apiClient.post(
        '/apple_sign_in',
        body: jsonEncode({
          'id_token': credential.identityToken,
          'auth_code': credential.authorizationCode,
        }),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        await SecureStorage.saveToken(responseData['user_id']);
        return true;
      }
      return false;
    } catch (e) {
      print('Error during Apple sign-in: $e');
      return false;
    }
  }

  static Future<bool> resetPassword(String email) async {
    final response = await _apiClient.post(
      '/forgot_password',
      body: jsonEncode({'email': email}),
      headers: {'Content-Type': 'application/json'},
    );
    return response.statusCode == 200;
  }

  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/utils/secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class Auth {
  static const _baseUrl = 'https://sycx-production.up.railway.app';

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

  static Future<bool> confirmResetPassword(
      String token, String newPassword) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/confirm_reset_password'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'token': token,
        'new_password': newPassword,
      }),
    );

    return response.statusCode == 200;
  }

  static Future<void> logout() async {
    await SecureStorage.deleteToken();
  }

  static Future<bool> googleSignIn() async {
    final GoogleSignIn googleSignIn = GoogleSignIn();
    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

    if (googleUser != null) {
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final response = await http.post(
        Uri.parse('$_baseUrl/google_signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
        }),
      );

      if (response.statusCode == 200) {
        await SecureStorage.saveToken(jsonDecode(response.body)['token']);
        return true;
      }
    }
    return false;
  }

  static Future<bool> appleSignIn() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final response = await http.post(
        Uri.parse('$_baseUrl/apple_signin'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_token': credential.identityToken,
          'authorization_code': credential.authorizationCode,
        }),
      );

      if (response.statusCode == 200) {
        await SecureStorage.saveToken(jsonDecode(response.body)['token']);
        return true;
      }
    } catch (e) {
      print(e);
    }
    return false;
  }
}

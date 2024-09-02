import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:sycx_flutter_app/services/api_client.dart';
import 'package:sycx_flutter_app/utils/secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class Auth {
  static final ApiClient _apiClient = ApiClient(httpClient: http.Client());

  static Future<bool> login(String email, String password) async {
    final response = await _apiClient.post(
      '/login',
      body: {'email': email, 'password': password},
    );

    if (response.statusCode == 200) {
      await SecureStorage.saveToken(jsonDecode(response.body)['token']);
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
      await SecureStorage.saveToken(jsonDecode(response.body)['token']);
      return true;
    }
    return false;
  }

  static Future<bool> resetPassword(String email) async {
    final response = await _apiClient.post(
      '/reset_password',
      body: {'email': email},
    );

    return response.statusCode == 200;
  }

  static Future<bool> confirmResetPassword(
      String token, String newPassword) async {
    final response = await _apiClient.post(
      '/confirm_reset_password',
      body: {
        'token': token,
        'new_password': newPassword,
      },
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
      final response = await _apiClient.post(
        '/google_signin',
        body: {
          'id_token': googleAuth.idToken,
          'access_token': googleAuth.accessToken,
        },
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

      final response = await _apiClient.post(
        '/apple_signin',
        body: {
          'id_token': credential.identityToken,
          'authorization_code': credential.authorizationCode,
        },
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

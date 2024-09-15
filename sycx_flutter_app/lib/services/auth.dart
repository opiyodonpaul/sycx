import 'dart:math';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:sycx_flutter_app/services/database.dart';
import 'package:sycx_flutter_app/models/user.dart' as app_user;

class Auth {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final Database _database = Database();

  // Email & Password Sign Up
  Future<Map<String, dynamic>> registerWithEmailAndPassword(
      String fullName,
      String userName,
      String email,
      String password,
      String userProfile) async {
    try {
      // Input validation
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email and password cannot be empty.'
        };
      }

      // Check if username already exists
      final existingUser = await _database.getUserByUsername(userName);
      if (existingUser != null) {
        return {'success': false, 'message': 'This username is already taken.'};
      }

      // Create the user in Firebase Auth
      UserCredential result = await _auth.createUserWithEmailAndPassword(
          email: email, password: password);
      User? user = result.user;
      if (user != null) {
        // Create the user document in Firestore
        await _database.createUser(app_user.User(
          id: user.uid,
          fullName: fullName,
          userName: userName,
          email: email,
          userProfile: userProfile,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          resetToken: null,
          resetTokenExpiration: null,
        ));
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Failed to create user.'};
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        return {
          'success': false,
          'message': 'An account with this email already exists.'
        };
      } else if (e.code == 'invalid-email') {
        return {'success': false, 'message': 'The email address is not valid.'};
      } else if (e.code == 'weak-password') {
        return {'success': false, 'message': 'The password is too weak.'};
      }
      return {
        'success': false,
        'message': e.message ?? 'An error occurred during registration.'
      };
    } catch (e) {
      print('Unexpected error during registration: $e');
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  // Username & Password Sign In (with email linking)
  Future<Map<String, dynamic>> signInWithEmailAndPassword(
      String usernameOrEmail, String password) async {
    try {
      String email = usernameOrEmail.contains('@')
          ? usernameOrEmail
          : await _getUserEmailByUsername(usernameOrEmail);

      UserCredential result = await _auth.signInWithEmailAndPassword(
          email: email, password: password);
      return {'success': true, 'user': result.user};
    } on FirebaseAuthException catch (e) {
      return {
        'success': false,
        'message': e.message ?? 'An error occurred during sign-in.'
      };
    } catch (e) {
      return {'success': false, 'message': 'An unexpected error occurred.'};
    }
  }

  // Google Sign In
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'message': 'Google sign-in was cancelled.'};
      }

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential result = await _auth.signInWithCredential(credential);
      User? user = result.user;
      if (user != null) {
        // Check if the user already exists in the database
        app_user.User? existingUser = await _database.getUser(user.uid);
        if (existingUser == null) {
          // If the user doesn't exist, create a new user in the database
          await _database.createUser(app_user.User(
            id: user.uid,
            fullName: user.displayName ?? '',
            userName: user.email?.split('@')[0] ?? '',
            email: user.email ?? '',
            userProfile: user.photoURL ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            resetToken: null,
            resetTokenExpiration: null,
          ));
        } else {
          // User exists, update their information
          await _database.updateUser(app_user.User(
            id: user.uid,
            fullName: user.displayName ?? existingUser.fullName,
            userName: existingUser.userName,
            email: user.email ?? existingUser.email,
            userProfile: user.photoURL ?? existingUser.userProfile,
            createdAt: existingUser.createdAt,
            updatedAt: DateTime.now(),
            resetToken: existingUser.resetToken,
            resetTokenExpiration: existingUser.resetTokenExpiration,
          ));
        }
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Failed to sign in with Google.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during Google sign-in.'
      };
    }
  }

// Apple Sign In
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      OAuthProvider oauthProvider = OAuthProvider('apple.com');
      final authCredential = oauthProvider.credential(
        idToken: credential.identityToken,
        accessToken: credential.authorizationCode,
      );

      UserCredential result = await _auth.signInWithCredential(authCredential);
      User? user = result.user;
      if (user != null) {
        // Check if the user already exists in the database
        app_user.User? existingUser = await _database.getUser(user.uid);
        if (existingUser == null) {
          // If the user doesn't exist, create a new user in the database
          await _database.createUser(app_user.User(
            id: user.uid,
            fullName:
                '${credential.givenName ?? ''} ${credential.familyName ?? ''}',
            userName: user.email?.split('@')[0] ?? '',
            email: user.email ?? '',
            userProfile: user.photoURL ?? '',
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
            resetToken: null,
            resetTokenExpiration: null,
          ));
        } else {
          // User exists, update their information
          await _database.updateUser(app_user.User(
            id: user.uid,
            fullName: existingUser.fullName,
            userName: existingUser.userName,
            email: user.email ?? existingUser.email,
            userProfile: user.photoURL ?? existingUser.userProfile,
            createdAt: existingUser.createdAt,
            updatedAt: DateTime.now(),
            resetToken: existingUser.resetToken,
            resetTokenExpiration: existingUser.resetTokenExpiration,
          ));
        }
        return {'success': true, 'user': user};
      }
      return {'success': false, 'message': 'Failed to sign in with Apple.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred during Apple sign-in.'
      };
    }
  }

  // Helper method to get user email by username
  Future<String> _getUserEmailByUsername(String username) async {
    try {
      app_user.User? user = await _database.getUserByUsername(username);
      if (user != null) {
        return user.email;
      } else {
        throw Exception('User not found');
      }
    } catch (e) {
      print('Error getting user email: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    return await _auth.signOut();
  }

  // Generate a random token
  String _generateToken() {
    const chars =
        'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random rnd = Random.secure();
    return List.generate(32, (index) => chars[rnd.nextInt(chars.length)])
        .join();
  }

  // Password Reset
  Future<Map<String, dynamic>> sendPasswordResetEmail(String email) async {
    try {
      // Check if user exists
      app_user.User? user = await _database.getUserByEmail(email);
      if (user == null) {
        return {'success': false, 'message': 'No user found with this email.'};
      }

      // Generate token and set expiration
      String token = _generateToken();
      DateTime expiration = DateTime.now().add(const Duration(hours: 1));

      // Save token to database
      await _database.setResetToken(user.id, token, expiration);

      // Send email
      await _auth.sendPasswordResetEmail(
        email: email,
        actionCodeSettings: ActionCodeSettings(
          url: 'https://sycx-reset-password-59c81.web.app?token=$token',
          handleCodeInApp: true,
          androidPackageName: 'com.donartkins.sycx',
          androidInstallApp: true,
          androidMinimumVersion: '12',
          iOSBundleId: 'com.donartkins.sycx',
          dynamicLinkDomain: 'sycx.page.link',
        ),
      );

      return {
        'success': true,
        'message': 'Password reset email sent successfully.',
        'expiration': expiration.toUtc().toString(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }

  // Verify Reset Token
  Future<Map<String, dynamic>> verifyResetToken(String token) async {
    try {
      app_user.User? user = await _database.getUserByResetToken(token);
      if (user == null) {
        return {'success': false, 'message': 'Invalid reset token.'};
      }

      if (user.resetTokenExpiration!.isBefore(DateTime.now())) {
        await _database.clearResetToken(user.id);
        return {'success': false, 'message': 'Reset token has expired.'};
      }

      return {'success': true, 'message': 'Token is valid.'};
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }

  // Reset Password
  Future<Map<String, dynamic>> resetPassword(
      String token, String newPassword) async {
    try {
      app_user.User? user = await _database.getUserByResetToken(token);
      if (user == null) {
        return {'success': false, 'message': 'Invalid reset token.'};
      }

      if (user.resetTokenExpiration!.isBefore(DateTime.now())) {
        await _database.clearResetToken(user.id);
        return {'success': false, 'message': 'Reset token has expired.'};
      }

      // Reset the password
      await _auth.confirmPasswordReset(code: token, newPassword: newPassword);

      // Clear the reset token
      await _database.clearResetToken(user.id);

      return {
        'success': true,
        'message': 'Password has been reset successfully.'
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'An unexpected error occurred: ${e.toString()}'
      };
    }
  }

  // Get Current User
  User? getCurrentUser() {
    return _auth.currentUser;
  }
}

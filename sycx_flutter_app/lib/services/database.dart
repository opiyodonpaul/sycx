import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sycx_flutter_app/models/user.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/models/feedback.dart';

class Database {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(User user) async {
    await _firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  Future<User?> getUser(String userId) async {
    DocumentSnapshot doc =
        await _firestore.collection('users').doc(userId).get();
    return doc.exists ? User.fromFirestore(doc) : null;
  }

  Future<User?> getUserByUsername(String username) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('userName', isEqualTo: username)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return User.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  Future<void> updateUser(User user) async {
    await _firestore
        .collection('users')
        .doc(user.id)
        .update(user.toFirestore());
  }

  Future<void> setResetToken(
      String userId, String token, DateTime expiration) async {
    await _firestore.collection('users').doc(userId).update({
      'resetToken': token,
      'resetTokenExpiration': Timestamp.fromDate(expiration),
    });
  }

  Future<void> clearResetToken(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'resetToken': FieldValue.delete(),
      'resetTokenExpiration': FieldValue.delete(),
    });
  }

  Future<User?> getUserByEmail(String email) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return User.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  Future<User?> getUserByResetToken(String token) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('users')
        .where('resetToken', isEqualTo: token)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      return User.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  // Summary operations
  Future<void> createSummary(Summary summary) async {
    try {
      await FirebaseFirestore.instance
          .collection('summaries')
          .doc(summary.id)
          .set(summary.toFirestore());
    } catch (e) {
      print('Error creating summary in Firestore: $e');
      rethrow;
    }
  }

  Future<void> deleteSummary(String summaryId) async {
    try {
      await FirebaseFirestore.instance
          .collection('summaries')
          .doc(summaryId)
          .delete();
    } catch (e) {
      print('Error deleting summary from Firestore: $e');
      rethrow;
    }
  }

  Future<List<Summary>> getUserSummaries(String userId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('summaries')
        .where('userId', isEqualTo: userId)
        .get();
    return querySnapshot.docs.map((doc) => Summary.fromFirestore(doc)).toList();
  }

  Future<void> updateSummary(Summary summary) async {
    await _firestore
        .collection('summaries')
        .doc(summary.id)
        .update(summary.toFirestore());
  }

  // Feedback operations
  Future<void> createFeedback(Feedback feedback) async {
    await _firestore.collection('feedback').add(feedback.toFirestore());
  }

  Future<List<Feedback>> getSummaryFeedback(String summaryId) async {
    QuerySnapshot querySnapshot = await _firestore
        .collection('feedback')
        .where('summaryId', isEqualTo: summaryId)
        .get();
    return querySnapshot.docs
        .map((doc) => Feedback.fromFirestore(doc))
        .toList();
  }

  Future<void> updateFeedback(Feedback feedback) async {
    await _firestore
        .collection('feedback')
        .doc(feedback.id)
        .update(feedback.toFirestore());
  }
}

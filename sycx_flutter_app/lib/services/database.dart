import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sycx_flutter_app/models/user.dart';
import 'package:sycx_flutter_app/models/summary.dart';
import 'package:sycx_flutter_app/models/feedback.dart';

class Database {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

  // User operations
  Future<void> createUser(User user) async {
    await firestore.collection('users').doc(user.id).set(user.toFirestore());
  }

  Future<User?> getUser(String userId) async {
    DocumentSnapshot doc =
        await firestore.collection('users').doc(userId).get();
    return doc.exists ? User.fromFirestore(doc) : null;
  }

  Future<User?> getUserByUsername(String username) async {
    QuerySnapshot querySnapshot = await firestore
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
    await firestore.collection('users').doc(user.id).update(user.toFirestore());
  }

  Future<void> setResetToken(
      String userId, String token, DateTime expiration) async {
    await firestore.collection('users').doc(userId).update({
      'resetToken': token,
      'resetTokenExpiration': Timestamp.fromDate(expiration),
    });
  }

  Future<void> clearResetToken(String userId) async {
    await firestore.collection('users').doc(userId).update({
      'resetToken': FieldValue.delete(),
      'resetTokenExpiration': FieldValue.delete(),
    });
  }

  Future<User?> getUserByEmail(String email) async {
    QuerySnapshot querySnapshot = await firestore
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
    QuerySnapshot querySnapshot = await firestore
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
      final summaryData = summary.toFirestore();
      await firestore
          .collection('summaries')
          .doc(summary.id)
          .set(summaryData);
    } catch (e) {
      print('Error creating summary in Firestore: $e');
      rethrow;
    }
  }

  Future<List<Summary>> getUserSummaries(String userId) async {
    try {
      final QuerySnapshot querySnapshot = await firestore
          .collection('summaries')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .get();

      return querySnapshot.docs.map((doc) {
        try {
          return Summary.fromFirestore(doc);
        } catch (e) {
          print('Error parsing summary document ${doc.id}: $e');
          // Return a default/empty summary instead of throwing
          return Summary(
            id: doc.id,
            userId: userId,
            originalDocuments: [],
            summaryContent: '', // Added required field
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(), // Added required field
            isPinned: false,
          );
        }
      }).toList();
    } catch (e) {
      print('Error fetching user summaries: $e');
      return [];
    }
  }

  Future<void> updateSummary(Summary summary) async {
    try {
      final summaryData = summary.toFirestore();
      await firestore
          .collection('summaries')
          .doc(summary.id)
          .update(summaryData);
    } catch (e) {
      print('Error updating summary: $e');
      rethrow;
    }
  }

  Future<void> deleteSummary(String summaryId) async {
    try {
      await firestore.collection('summaries').doc(summaryId).delete();
    } catch (e) {
      print('Error deleting summary from Firestore: $e');
      rethrow;
    }
  }

  // Feedback operations
  Future<void> createFeedback(Feedback feedback) async {
    await firestore.collection('feedback').add(feedback.toFirestore());
  }

  Future<List<Feedback>> getSummaryFeedback(String summaryId) async {
    QuerySnapshot querySnapshot = await firestore
        .collection('feedback')
        .where('summaryId', isEqualTo: summaryId)
        .get();
    return querySnapshot.docs
        .map((doc) => Feedback.fromFirestore(doc))
        .toList();
  }

  Future<void> updateFeedback(Feedback feedback) async {
    await firestore
        .collection('feedback')
        .doc(feedback.id)
        .update(feedback.toFirestore());
  }

  Future<void> saveSearch(String userId, String query) async {
    try {
      await firestore.collection('searches').add({
        'userId': userId,
        'query': query,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error saving search: $e');
    }
  }

  Future<List<String>> getRecentSearches(String userId, {int limit = 5}) async {
    try {
      QuerySnapshot searchesSnapshot = await firestore
          .collection('searches')
          .where('userId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return searchesSnapshot.docs
          .map((doc) => doc['query'] as String)
          .toList();
    } catch (e) {
      print('Error fetching searches: $e');
      return [];
    }
  }

  Future<void> clearAllSearches(String userId) async {
    try {
      // Get all search records for the user
      QuerySnapshot searchesSnapshot = await firestore
          .collection('searches')
          .where('userId', isEqualTo: userId)
          .get();

      // Delete each search record
      for (DocumentSnapshot doc in searchesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error clearing searches: $e');
    }
  }

  Future<void> removeSearch(String userId, String query) async {
    try {
      // Find and delete the specific search record
      QuerySnapshot searchesSnapshot = await firestore
          .collection('searches')
          .where('userId', isEqualTo: userId)
          .where('query', isEqualTo: query)
          .get();

      for (DocumentSnapshot doc in searchesSnapshot.docs) {
        await doc.reference.delete();
      }
    } catch (e) {
      print('Error removing search: $e');
    }
  }
}

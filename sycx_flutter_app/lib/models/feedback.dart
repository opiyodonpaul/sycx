import 'package:cloud_firestore/cloud_firestore.dart';

class Feedback {
  final String id;
  final String userId;
  final String summaryId;
  final String feedbackText;
  final num rating;
  final DateTime createdAt;
  final DateTime updatedAt;

  Feedback({
    required this.id,
    required this.userId,
    required this.summaryId,
    required this.feedbackText,
    required this.rating,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Feedback.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Feedback(
      id: doc.id,
      userId: data['userId'] ?? '',
      summaryId: data['summaryId'] ?? '',
      feedbackText: data['feedbackText'] ?? '',
      rating: data['rating'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'summaryId': summaryId,
      'feedbackText': feedbackText,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

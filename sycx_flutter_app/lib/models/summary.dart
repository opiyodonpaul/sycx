import 'package:cloud_firestore/cloud_firestore.dart';

class Summary {
  final String id;
  final String userId;
  final String documentTitle;
  final String documentContent;
  final DateTime summaryDate;
  final String summaryContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Summary({
    required this.id,
    required this.userId,
    required this.documentTitle,
    required this.documentContent,
    required this.summaryDate,
    required this.summaryContent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Summary.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Summary(
      id: doc.id,
      userId: data['userId'] ?? '',
      documentTitle: data['documentTitle'] ?? '',
      documentContent: data['documentContent'] ?? '',
      summaryDate: (data['summaryDate'] as Timestamp).toDate(),
      summaryContent: data['summaryContent'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'documentTitle': documentTitle,
      'documentContent': documentContent,
      'summaryDate': Timestamp.fromDate(summaryDate),
      'summaryContent': summaryContent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

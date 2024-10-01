import 'package:cloud_firestore/cloud_firestore.dart';

class Summary {
  final String id;
  final String userId;
  final List<OriginalDocument> originalDocuments;
  final String summaryContent;
  final DateTime createdAt;
  final DateTime updatedAt;

  Summary({
    required this.id,
    required this.userId,
    required this.originalDocuments,
    required this.summaryContent,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Summary.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Summary(
      id: doc.id,
      userId: data['userId'] ?? '',
      originalDocuments: (data['originalDocuments'] as List<dynamic>?)
              ?.map((doc) => OriginalDocument.fromMap(doc))
              .toList() ??
          [],
      summaryContent: data['summaryContent'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'],
      userId: json['userId'],
      originalDocuments: (json['originalDocuments'] as List<dynamic>?)
              ?.map((doc) => OriginalDocument.fromMap(doc))
              .toList() ??
          [],
      summaryContent: json['summaryContent'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originalDocuments': originalDocuments.map((doc) => doc.toMap()).toList(),
      'summaryContent': summaryContent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }
}

class OriginalDocument {
  final String title;
  final String content;

  OriginalDocument({
    required this.title,
    required this.content,
  });

  factory OriginalDocument.fromMap(Map<String, dynamic> map) {
    return OriginalDocument(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
    };
  }
}

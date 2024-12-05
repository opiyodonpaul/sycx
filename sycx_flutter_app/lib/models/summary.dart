import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class Summary {
  final String id;
  final String userId;
  final List<OriginalDocument> originalDocuments;
  final String summaryContent;
  final DateTime createdAt;
  final DateTime updatedAt;
  bool isPinned;
  String? title;

  Summary({
    this.id = '',
    required this.userId,
    required this.originalDocuments,
    required this.summaryContent,
    required this.createdAt,
    required this.updatedAt,
    this.isPinned = false,
  }) {
    // Set title based on first original document or default
    title = originalDocuments.isNotEmpty
        ? originalDocuments.first.title
        : 'Untitled';
  }

  Future<String> getFormattedSummaryText() async {
    // Simply return the summaryContent as it is now unencoded
    return summaryContent;
  }

  factory Summary.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    List<OriginalDocument> documents = [];
    if (data['originalDocuments'] != null) {
      documents = (data['originalDocuments'] as List<dynamic>)
          .map((doc) => OriginalDocument.fromMap(doc as Map<String, dynamic>))
          .toList();
    }

    DateTime created = (data['createdAt'] as Timestamp).toDate();
    DateTime updated = (data['updatedAt'] as Timestamp).toDate();

    return Summary(
      id: doc.id,
      userId: data['userId'] ?? '',
      originalDocuments: documents,
      summaryContent: data['summaryContent'] ?? '',
      createdAt: created,
      updatedAt: updated,
      isPinned: data['isPinned'] ?? false,
    );
  }

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      originalDocuments: (json['originalDocuments'] as List<dynamic>?)
              ?.map((doc) =>
                  OriginalDocument.fromMap(doc as Map<String, dynamic>))
              .toList() ??
          [],
      summaryContent: json['summaryContent'] ?? '',
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] is DateTime
              ? json['createdAt']
              : DateTime.parse(json['createdAt']))
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is DateTime
              ? json['updatedAt']
              : DateTime.parse(json['updatedAt']))
          : DateTime.now(),
      isPinned: json['isPinned'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'originalDocuments': originalDocuments.map((doc) => doc.toMap()).toList(),
      'summaryContent': summaryContent,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'isPinned': isPinned,
      'title': title,
    };
  }

  Map<String, dynamic> toCardFormat() {
    return {
      'id': id,
      'title': title ?? 'Untitled',
      'originalDocuments': originalDocuments.map((doc) => doc.toMap()).toList(),
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      'isPinned': isPinned,
      'summaryContent': summaryContent,
    };
  }

  Summary copyWith({
    String? id,
    String? userId,
    List<OriginalDocument>? originalDocuments,
    String? summaryContent,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isPinned,
  }) {
    return Summary(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      originalDocuments: originalDocuments ?? this.originalDocuments,
      summaryContent: summaryContent ?? this.summaryContent,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isPinned: isPinned ?? this.isPinned,
    );
  }

  List<int> decodeDocumentContent(OriginalDocument doc) {
    try {
      return base64Decode(doc.content);
    } catch (e) {
      print('Error decoding document content: $e');
      return [];
    }
  }
}

class OriginalDocument {
  final String title;
  final String content; // Base64 encoded content
  final String? type;

  OriginalDocument({
    required this.title,
    required this.content,
    this.type,
  });

  factory OriginalDocument.fromMap(Map<String, dynamic> map) {
    return OriginalDocument(
      title: map['title'] ?? '',
      content: map['content'] ?? '',
      type: map['type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'content': content,
      if (type != null) 'type': type,
    };
  }
}

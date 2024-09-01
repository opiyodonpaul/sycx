class Summary {
  final String id;
  final String userId;
  final String title;
  final String summaryText;
  final DateTime createdAt;

  Summary({
    required this.id,
    required this.userId,
    required this.title,
    required this.summaryText,
    required this.createdAt,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['summary_id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? 'Untitled',
      summaryText: json['summary'] ?? '',
      createdAt:
          DateTime.parse(json['created_at'] ?? DateTime.now().toString()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'summary_id': id,
      'user_id': userId,
      'title': title,
      'summary': summaryText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}

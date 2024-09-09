class Summary {
  final String id;
  final String title;
  final String content;
  final String date;

  Summary({
    required this.id,
    required this.title,
    required this.content,
    required this.date,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: json['date'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'date': date,
    };
  }
}

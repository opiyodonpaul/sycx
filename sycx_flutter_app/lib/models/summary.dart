class Summary {
  final String? id;
  final String? title;
  final String? content;
  final String? date;
  final bool isPinned;
  final String? image;

  Summary({
    this.id,
    this.title,
    this.content,
    this.date,
    this.isPinned = false,
    this.image,
  });

  factory Summary.fromJson(Map<String, dynamic> json) {
    return Summary(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      date: json['date'],
      isPinned: json['isPinned'] ?? false,
      image: json['image'],
    );
  }
}

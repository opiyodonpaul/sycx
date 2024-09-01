class User {
  final String id;
  final String username;
  final String email;
  final String? profilePic;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.profilePic,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'profile_pic': profilePic,
    };
  }
}

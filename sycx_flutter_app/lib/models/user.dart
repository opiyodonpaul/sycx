class User {
  final String id;
  final String fullname;
  final String username;
  final String email;
  final String? profilePic;

  User({
    required this.id,
    required this.fullname,
    required this.username,
    required this.email,
    this.profilePic,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? '',
      fullname: json['fullname'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      profilePic: json['profile_pic'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullname': fullname,
      'username': username,
      'email': email,
      'profile_pic': profilePic,
    };
  }
}

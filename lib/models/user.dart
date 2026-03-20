class User {
  final int userId;
  final String fullName;
  final String email;
  final String role;
  final String? avatarUrl;
  final String? bio;

  User({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    this.avatarUrl,
    this.bio,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'student',
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
    );
  }
  
  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'full_name': fullName,
    'email': email,
    'role': role,
    'avatar_url': avatarUrl,
    'bio': bio,
  };
}

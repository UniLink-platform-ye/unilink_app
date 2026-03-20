class Comment {
  final int commentId;
  final int postId;
  final int userId;
  final String fullName;
  final String content;
  final String createdAt;

  Comment({
    required this.commentId,
    required this.postId,
    required this.userId,
    required this.fullName,
    required this.content,
    required this.createdAt,
  });

  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      commentId: json['comment_id'] is int ? json['comment_id'] : int.tryParse(json['comment_id']?.toString() ?? '0') ?? 0,
      postId: json['post_id'] is int ? json['post_id'] : int.tryParse(json['post_id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name'] ?? 'User',
      content: json['content'] ?? '',
      createdAt: json['created_at'] ?? '',
    );
  }
}

class Post {
  final int postId;
  final int userId;
  final String fullName;
  final String content;
  final String type;
  final String createdAt;
  final int? groupId;
  final String? groupName;
  final int commentsCount;
  final int likesCount;

  Post({
    required this.postId,
    required this.userId,
    required this.fullName,
    required this.content,
    required this.type,
    required this.createdAt,
    this.groupId,
    this.groupName,
    this.commentsCount = 0,
    this.likesCount = 0,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      postId: json['post_id'] is int ? json['post_id'] : int.tryParse(json['post_id']?.toString() ?? '0') ?? 0,
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? '0') ?? 0,
      fullName: json['full_name'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? json['post_type'] ?? 'post',
      createdAt: json['created_at'] ?? '',
      groupId: json['group_id'] != null ? (json['group_id'] is int ? json['group_id'] : int.tryParse(json['group_id'].toString())) : null,
      groupName: json['group_name'],
      commentsCount: json['comments_count'] is int ? json['comments_count'] : int.tryParse(json['comments_count']?.toString() ?? '0') ?? 0,
      likesCount: json['likes_count'] is int ? json['likes_count'] : int.tryParse(json['likes_count']?.toString() ?? '0') ?? 0,
    );
  }
  
  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'user_id': userId,
    'full_name': fullName,
    'content': content,
    'type': type,
    'created_at': createdAt,
    'group_id': groupId,
    'group_name': groupName,
    'comments_count': commentsCount,
    'likes_count': likesCount,
  };  
}

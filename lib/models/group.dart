class Group {
  final int groupId;
  final String name;
  final String description;
  final String type;
  final String privacy;
  final int createdBy;
  final String createdAt;

  Group({
    required this.groupId,
    required this.name,
    required this.description,
    required this.type,
    required this.privacy,
    required this.createdBy,
    required this.createdAt,
  });

  factory Group.fromJson(Map<String, dynamic> json) {
    return Group(
      groupId: json['group_id'] is int ? json['group_id'] : int.tryParse(json['group_id']?.toString() ?? '0') ?? 0,
      name: json['group_name'] ?? '',
      description: json['description'] ?? '',
      type: json['group_type'] ?? 'study',
      privacy: json['privacy'] ?? 'public',
      createdBy: json['created_by'] is int ? json['created_by'] : int.tryParse(json['created_by']?.toString() ?? '0') ?? 0,
      createdAt: json['created_at'] ?? '',
    );
  }
  
  Map<String, dynamic> toJson() => {
    'group_id': groupId,
    'group_name': name,
    'description': description,
    'group_type': type,
    'privacy': privacy,
    'created_by': createdBy,
    'created_at': createdAt,
  };  
}

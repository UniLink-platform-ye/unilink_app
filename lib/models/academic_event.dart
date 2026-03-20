class AcademicEvent {
  final int eventId;
  final int ownerUserId;
  final String title;
  final String type;
  final String startAt;
  final String? endAt;
  final String? description;
  final String? location;
  final bool allDay;
  final String? courseName;
  final String? groupName;

  AcademicEvent({
    required this.eventId,
    required this.ownerUserId,
    required this.title,
    required this.type,
    required this.startAt,
    this.endAt,
    this.description,
    this.location,
    this.allDay = false,
    this.courseName,
    this.groupName,
  });

  factory AcademicEvent.fromJson(Map<String, dynamic> json) {
    return AcademicEvent(
      eventId: json['event_id'] is int ? json['event_id'] : int.tryParse(json['event_id']?.toString() ?? '0') ?? 0,
      ownerUserId: json['owner_user_id'] is int ? json['owner_user_id'] : int.tryParse(json['owner_user_id']?.toString() ?? '0') ?? 0,
      title: json['title'] ?? '',
      type: json['event_type'] ?? 'other',
      startAt: json['start_at'] ?? '',
      endAt: json['end_at'],
      description: json['description'],
      location: json['location'],
      allDay: (json['all_day'] is int ? json['all_day'] : int.tryParse(json['all_day']?.toString() ?? '0')) == 1,
      courseName: json['course_name'],
      groupName: json['group_name'],
    );
  }
}

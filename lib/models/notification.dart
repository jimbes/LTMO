class Notification {
  final int id;
  final int userId;
  final int coupleId;
  final String type;
  final String subject;
  final String message;
  final String status;
  final int retryCount;
  final DateTime? nextRetryAt;
  final String? failedReason;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.coupleId,
    required this.type,
    required this.subject,
    required this.message,
    required this.status,
    required this.retryCount,
    this.nextRetryAt,
    this.failedReason,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'],
      userId: json['user_id'],
      coupleId: json['couple_id'],
      type: json['type'],
      subject: json['subject'],
      message: json['message'],
      status: json['status'],
      retryCount: json['retry_count'] ?? 0,
      nextRetryAt: json['next_retry_at'] != null
          ? DateTime.parse(json['next_retry_at'])
          : null,
      failedReason: json['failed_reason'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'couple_id': coupleId,
      'type': type,
      'subject': subject,
      'message': message,
      'status': status,
      'retry_count': retryCount,
      'next_retry_at': nextRetryAt?.toIso8601String(),
      'failed_reason': failedReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Notification copyWith({
    int? id,
    int? userId,
    int? coupleId,
    String? type,
    String? subject,
    String? message,
    String? status,
    int? retryCount,
    DateTime? nextRetryAt,
    String? failedReason,
    DateTime? createdAt,
  }) {
    return Notification(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      coupleId: coupleId ?? this.coupleId,
      type: type ?? this.type,
      subject: subject ?? this.subject,
      message: message ?? this.message,
      status: status ?? this.status,
      retryCount: retryCount ?? this.retryCount,
      nextRetryAt: nextRetryAt ?? this.nextRetryAt,
      failedReason: failedReason ?? this.failedReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

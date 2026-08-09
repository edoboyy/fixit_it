enum NotificationType {
  bookingAccepted,
  bookingRejected,
  artisanTravelling,
  workStarted,
  jobCompleted,
  paymentReleased,
  bookingCancelled,
  newBooking,
  adminApprovedJob,
  adminRejectedJob,
  artisanVerified,
  awaitingAdminApproval;

  String get value => name;

  static NotificationType fromString(String? value) {
    return NotificationType.values.firstWhere(
      (type) => type.name == value,
      orElse: () => NotificationType.newBooking,
    );
  }

  String get defaultTitle => switch (this) {
        NotificationType.bookingAccepted => 'Booking Accepted',
        NotificationType.bookingRejected => 'Booking Rejected',
        NotificationType.artisanTravelling => 'Artisan On The Way',
        NotificationType.workStarted => 'Work Started',
        NotificationType.jobCompleted => 'Job Completed',
        NotificationType.paymentReleased => 'Payment Released',
        NotificationType.bookingCancelled => 'Booking Cancelled',
        NotificationType.newBooking => 'New Job Assigned',
        NotificationType.adminApprovedJob => 'Job Approved',
        NotificationType.adminRejectedJob => 'Job Rejected by Admin',
        NotificationType.artisanVerified => 'Account Verified',
        NotificationType.awaitingAdminApproval => 'New Booking Needs Approval',
      };
}

class NotificationModel {
  const NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.body,
    required this.type,
    this.bookingId,
    this.isRead = false,
    this.createdAt,
  });

  final String id;
  final String userId;
  final String title;
  final String body;
  final NotificationType type;
  final String? bookingId;
  final bool isRead;
  final DateTime? createdAt;

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return NotificationModel(
      id: id ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      type: NotificationType.fromString(map['type'] as String?),
      bookingId: map['bookingId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'body': body,
      'type': type.value,
      'bookingId': bookingId,
      'isRead': isRead,
      'createdAt': createdAt?.toIso8601String(),
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? body,
    NotificationType? type,
    String? bookingId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      body: body ?? this.body,
      type: type ?? this.type,
      bookingId: bookingId ?? this.bookingId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}


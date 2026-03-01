// lib/core/models/notification_model.dart

enum NotificationType {
  bookingNew,
  bookingConfirmed,
  bookingCancelled,
  paymentReceived,
  invoiceDue,
  invoiceOverdue,
  payrollReady,
  attendanceAlert,
  employeeAdded,
  general,
}

class NotificationModel {
  final String id;
  final String businessId;
  final String title;
  final String body;
  final NotificationType type;
  final bool isRead;
  final String? referenceId;   // bookingId, invoiceId, etc.
  final String? referenceType; // 'booking', 'invoice', 'payment', etc.
  final DateTime createdAt;
  final DateTime? readAt;

  NotificationModel({
    required this.id,
    required this.businessId,
    required this.title,
    required this.body,
    required this.type,
    this.isRead = false,
    this.referenceId,
    this.referenceType,
    required this.createdAt,
    this.readAt,
  });

  factory NotificationModel.fromMap(Map<String, dynamic> map, String id) {
    return NotificationModel(
      id: id,
      businessId: map['businessId'] ?? '',
      title: map['title'] ?? '',
      body: map['body'] ?? '',
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.general,
      ),
      isRead: map['isRead'] ?? false,
      referenceId: map['referenceId'],
      referenceType: map['referenceType'],
      createdAt: DateTime.parse(
          map['createdAt'] ?? DateTime.now().toIso8601String()),
      readAt: map['readAt'] != null ? DateTime.parse(map['readAt']) : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'title': title,
        'body': body,
        'type': type.name,
        'isRead': isRead,
        'referenceId': referenceId,
        'referenceType': referenceType,
        'createdAt': createdAt.toIso8601String(),
        'readAt': readAt?.toIso8601String(),
      };

  NotificationModel copyWith({bool? isRead, DateTime? readAt}) {
    return NotificationModel(
      id: id,
      businessId: businessId,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      referenceId: referenceId,
      referenceType: referenceType,
      createdAt: createdAt,
      readAt: readAt ?? this.readAt,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────
  String get typeIcon {
    switch (type) {
      case NotificationType.bookingNew:       return '📅';
      case NotificationType.bookingConfirmed: return '✅';
      case NotificationType.bookingCancelled: return '❌';
      case NotificationType.paymentReceived:  return '💰';
      case NotificationType.invoiceDue:       return '📄';
      case NotificationType.invoiceOverdue:   return '⚠️';
      case NotificationType.payrollReady:     return '💼';
      case NotificationType.attendanceAlert:  return '🕐';
      case NotificationType.employeeAdded:    return '👤';
      case NotificationType.general:          return '🔔';
    }
  }

  String get timeAgo {
    final diff = DateTime.now().difference(createdAt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }
}

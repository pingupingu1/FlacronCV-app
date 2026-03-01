class AttendanceModel {
  final String id;
  final String userId;
  final DateTime checkIn;
  final DateTime? checkOut;

  AttendanceModel({
    required this.id,
    required this.userId,
    required this.checkIn,
    this.checkOut,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String docId) {
    return AttendanceModel(
      id: docId,
      userId: map['userId'],
      checkIn: map['checkIn'].toDate(),
      checkOut:
          map['checkOut'] != null ? map['checkOut'].toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'checkIn': checkIn,
      'checkOut': checkOut,
    };
  }
}

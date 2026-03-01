// lib/core/models/business_hours_model.dart

class DayHours {
  final bool isOpen;
  final String openTime;  // "09:00"
  final String closeTime; // "17:00"

  DayHours({
    required this.isOpen,
    required this.openTime,
    required this.closeTime,
  });

  factory DayHours.fromMap(Map<String, dynamic> map) {
    return DayHours(
      isOpen: map['isOpen'] ?? false,
      openTime: map['openTime'] ?? '09:00',
      closeTime: map['closeTime'] ?? '17:00',
    );
  }

  Map<String, dynamic> toMap() => {
    'isOpen': isOpen,
    'openTime': openTime,
    'closeTime': closeTime,
  };

  DayHours copyWith({bool? isOpen, String? openTime, String? closeTime}) {
    return DayHours(
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }
}

class BusinessHoursModel {
  final String businessId;
  final DayHours monday;
  final DayHours tuesday;
  final DayHours wednesday;
  final DayHours thursday;
  final DayHours friday;
  final DayHours saturday;
  final DayHours sunday;

  BusinessHoursModel({
    required this.businessId,
    required this.monday,
    required this.tuesday,
    required this.wednesday,
    required this.thursday,
    required this.friday,
    required this.saturday,
    required this.sunday,
  });

  factory BusinessHoursModel.defaultHours(String businessId) {
    final weekday = DayHours(isOpen: true, openTime: '09:00', closeTime: '17:00');
    final weekend = DayHours(isOpen: false, openTime: '09:00', closeTime: '17:00');
    return BusinessHoursModel(
      businessId: businessId,
      monday: weekday,
      tuesday: weekday,
      wednesday: weekday,
      thursday: weekday,
      friday: weekday,
      saturday: weekend,
      sunday: weekend,
    );
  }

  factory BusinessHoursModel.fromMap(Map<String, dynamic> map, String businessId) {
    DayHours parse(String key) {
      final data = map[key];
      if (data == null) return DayHours(isOpen: false, openTime: '09:00', closeTime: '17:00');
      return DayHours.fromMap(Map<String, dynamic>.from(data));
    }
    return BusinessHoursModel(
      businessId: businessId,
      monday: parse('monday'),
      tuesday: parse('tuesday'),
      wednesday: parse('wednesday'),
      thursday: parse('thursday'),
      friday: parse('friday'),
      saturday: parse('saturday'),
      sunday: parse('sunday'),
    );
  }

  Map<String, dynamic> toMap() => {
    'monday': monday.toMap(),
    'tuesday': tuesday.toMap(),
    'wednesday': wednesday.toMap(),
    'thursday': thursday.toMap(),
    'friday': friday.toMap(),
    'saturday': saturday.toMap(),
    'sunday': sunday.toMap(),
    'updatedAt': DateTime.now().toIso8601String(),
  };

  List<MapEntry<String, DayHours>> get days => [
    MapEntry('Monday', monday),
    MapEntry('Tuesday', tuesday),
    MapEntry('Wednesday', wednesday),
    MapEntry('Thursday', thursday),
    MapEntry('Friday', friday),
    MapEntry('Saturday', saturday),
    MapEntry('Sunday', sunday),
  ];

  BusinessHoursModel updateDay(String dayName, DayHours hours) {
    return BusinessHoursModel(
      businessId: businessId,
      monday: dayName == 'Monday' ? hours : monday,
      tuesday: dayName == 'Tuesday' ? hours : tuesday,
      wednesday: dayName == 'Wednesday' ? hours : wednesday,
      thursday: dayName == 'Thursday' ? hours : thursday,
      friday: dayName == 'Friday' ? hours : friday,
      saturday: dayName == 'Saturday' ? hours : saturday,
      sunday: dayName == 'Sunday' ? hours : sunday,
    );
  }
}

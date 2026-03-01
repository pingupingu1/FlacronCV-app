// lib/core/models/employee_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

enum EmployeeRole { staff, manager, admin }
enum EmploymentType { fullTime, partTime, contract, intern }

class EmployeeModel {
  final String id;
  final String businessId;
  final String? userId;
  final String fullName;
  final String email;
  final String phone;
  final String? photoUrl;
  final EmployeeRole role;
  final EmploymentType employmentType;
  final String position;
  final double hourlyRate;
  final DateTime hireDate;
  final bool isActive;
  final String? notes;
  final DateTime createdAt;
  final DateTime? updatedAt;

  EmployeeModel({
    required this.id,
    required this.businessId,
    this.userId,
    required this.fullName,
    required this.email,
    required this.phone,
    this.photoUrl,
    required this.role,
    required this.employmentType,
    required this.position,
    required this.hourlyRate,
    required this.hireDate,
    this.isActive = true,
    this.notes,
    required this.createdAt,
    this.updatedAt,
  });

  factory EmployeeModel.fromFirestore(DocumentSnapshot doc) {
    final map = doc.data() as Map<String, dynamic>;
    return EmployeeModel.fromMap(map, doc.id);
  }

  factory EmployeeModel.fromMap(Map<String, dynamic> map, String id) {
    return EmployeeModel(
      id: id,
      businessId: map['businessId'] ?? '',
      userId: map['userId'],
      fullName: map['fullName'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      photoUrl: map['photoUrl'],
      role: EmployeeRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => EmployeeRole.staff,
      ),
      employmentType: EmploymentType.values.firstWhere(
        (e) => e.name == map['employmentType'],
        orElse: () => EmploymentType.fullTime,
      ),
      position: map['position'] ?? '',
      hourlyRate: (map['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      hireDate: map['hireDate'] != null
          ? DateTime.parse(map['hireDate'])
          : DateTime.now(),
      isActive: map['isActive'] ?? true,
      notes: map['notes'],
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() => {
        'businessId': businessId,
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'role': role.name,
        'employmentType': employmentType.name,
        'position': position,
        'hourlyRate': hourlyRate,
        'hireDate': hireDate.toIso8601String(),
        'isActive': isActive,
        'notes': notes,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt?.toIso8601String(),
      };

  String get initials {
    final parts = fullName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return fullName.isNotEmpty ? fullName[0].toUpperCase() : '?';
  }

  String get roleLabel {
    switch (role) {
      case EmployeeRole.staff:   return 'Staff';
      case EmployeeRole.manager: return 'Manager';
      case EmployeeRole.admin:   return 'Admin';
    }
  }

  String get employmentLabel {
    switch (employmentType) {
      case EmploymentType.fullTime: return 'Full Time';
      case EmploymentType.partTime: return 'Part Time';
      case EmploymentType.contract: return 'Contract';
      case EmploymentType.intern:   return 'Intern';
    }
  }

  String get formattedHourlyRate => '\$${hourlyRate.toStringAsFixed(2)}/hr';

  EmployeeModel copyWith({
    String? fullName,
    String? email,
    String? phone,
    String? position,
    EmployeeRole? role,
    EmploymentType? employmentType,
    double? hourlyRate,
    bool? isActive,
    String? notes,
  }) {
    return EmployeeModel(
      id: id,
      businessId: businessId,
      userId: userId,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      photoUrl: photoUrl,
      role: role ?? this.role,
      employmentType: employmentType ?? this.employmentType,
      position: position ?? this.position,
      hourlyRate: hourlyRate ?? this.hourlyRate,
      hireDate: hireDate,
      isActive: isActive ?? this.isActive,
      notes: notes ?? this.notes,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }
}

// lib/core/models/user_model.dart

enum UserRole {
  superAdmin,
  businessOwner,
  employee,
  customer,
}

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? phoneNumber;
  final String? photoUrl;
  final UserRole role;
  final String? businessId; // Links to business for owners/employees
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.phoneNumber,
    this.photoUrl,
    required this.role,
    this.businessId,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  // Convert from Firestore
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      displayName: map['displayName'],
      phoneNumber: map['phoneNumber'],
      photoUrl: map['photoUrl'],
      role: UserRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => UserRole.customer,
      ),
      businessId: map['businessId'],
      isActive: map['isActive'] ?? true,
      createdAt: DateTime.parse(map['createdAt']),
      updatedAt: map['updatedAt'] != null ? DateTime.parse(map['updatedAt']) : null,
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'phoneNumber': phoneNumber,
      'photoUrl': photoUrl,
      'role': role.name,
      'businessId': businessId,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  // Copy with modifications
  UserModel copyWith({
    String? displayName,
    String? phoneNumber,
    String? photoUrl,
    UserRole? role,
    String? businessId,
    bool? isActive,
    DateTime? updatedAt,
  }) {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName ?? this.displayName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoUrl: photoUrl ?? this.photoUrl,
      role: role ?? this.role,
      businessId: businessId ?? this.businessId,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  bool get isBusinessOwner => role == UserRole.businessOwner;
  bool get isEmployee => role == UserRole.employee;
  bool get isCustomer => role == UserRole.customer;
  bool get isSuperAdmin => role == UserRole.superAdmin;
}
class UserModel {
  final String uid;
  final String name;
  final String email;
  final String role; // owner, employee
  final String businessId;
  final bool isActive;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    required this.businessId,
    required this.isActive,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      name: map['name'],
      email: map['email'],
      role: map['role'],
      businessId: map['businessId'],
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
      'role': role,
      'businessId': businessId,
      'isActive': isActive,
    };
  }
}

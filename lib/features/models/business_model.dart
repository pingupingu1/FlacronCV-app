class BusinessModel {
  final String id;
  final String name;
  final String ownerId;
  final String phone;
  final String address;
  final DateTime createdAt;

  BusinessModel({
    required this.id,
    required this.name,
    required this.ownerId,
    required this.phone,
    required this.address,
    required this.createdAt,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map, String docId) {
    return BusinessModel(
      id: docId,
      name: map['name'],
      ownerId: map['ownerId'],
      phone: map['phone'],
      address: map['address'],
      createdAt: map['createdAt'].toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerId': ownerId,
      'phone': phone,
      'address': address,
      'createdAt': createdAt,
    };
  }
}

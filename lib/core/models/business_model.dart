// lib/core/models/business_model.dart

class BusinessModel {
  final String id;
  final String ownerId;
  final String name;
  final String category;
  final String? description;
  final String? phone;
  final String? email;
  final String? address;
  final String? city;
  final String? state;
  final String? zip;
  final String? website;
  final String? logoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  BusinessModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.category,
    this.description,
    this.phone,
    this.email,
    this.address,
    this.city,
    this.state,
    this.zip,
    this.website,
    this.logoUrl,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory BusinessModel.fromMap(Map<String, dynamic> map, String id) {
    return BusinessModel(
      id: id,
      ownerId: map['ownerId'] ?? '',
      name: map['name'] ?? '',
      category: map['category'] ?? '',
      description: map['description'],
      phone: map['phone'],
      email: map['email'],
      address: map['address'],
      city: map['city'],
      state: map['state'],
      zip: map['zip'],
      website: map['website'],
      logoUrl: map['logoUrl'],
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'])
          : DateTime.now(),
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'ownerId': ownerId,
      'name': name,
      'category': category,
      'description': description,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'state': state,
      'zip': zip,
      'website': website,
      'logoUrl': logoUrl,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  BusinessModel copyWith({
    String? name,
    String? category,
    String? description,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? state,
    String? zip,
    String? website,
    String? logoUrl,
    bool? isActive,
  }) {
    return BusinessModel(
      id: id,
      ownerId: ownerId,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      state: state ?? this.state,
      zip: zip ?? this.zip,
      website: website ?? this.website,
      logoUrl: logoUrl ?? this.logoUrl,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  String get displayAddress {
    final parts = [address, city, state, zip].where((p) => p != null && p.isNotEmpty).toList();
    return parts.join(', ');
  }
}

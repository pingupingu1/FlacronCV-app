// lib/core/models/service_model.dart

class ServiceModel {
  final String id;
  final String businessId;
  final String name;
  final double price;
  final int durationMinutes;
  final String? description;
  final String? category;
  final String color;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ServiceModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.price,
    required this.durationMinutes,
    this.description,
    this.category,
    this.color = '#FF6B00',
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      businessId: map['businessId'] ?? '',
      name: map['name'] ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: map['durationMinutes'] as int? ?? 60,
      description: map['description'],
      category: map['category'],
      color: map['color'] ?? '#FF6B00',
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
      'businessId': businessId,
      'name': name,
      'price': price,
      'durationMinutes': durationMinutes,
      'description': description,
      'category': category,
      'color': color,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  String get formattedPrice => '\$${price.toStringAsFixed(2)}';
  String get formattedDuration {
    if (durationMinutes < 60) return '${durationMinutes}min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}

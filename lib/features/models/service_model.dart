class ServiceModel {
  final String id;
  final String businessId;
  final String name;
  final int duration; // minutes
  final double price;
  final bool isActive;

  ServiceModel({
    required this.id,
    required this.businessId,
    required this.name,
    required this.duration,
    required this.price,
    required this.isActive,
  });

  factory ServiceModel.fromMap(Map<String, dynamic> map, String docId) {
    return ServiceModel(
      id: docId,
      businessId: map['businessId'],
      name: map['name'],
      duration: map['duration'],
      price: (map['price'] as num).toDouble(),
      isActive: map['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'name': name,
      'duration': duration,
      'price': price,
      'isActive': isActive,
    };
  }
}

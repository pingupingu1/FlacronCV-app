enum EmploymentType {
  fullTime,
  partTime,
  contract,
  // you can add more types if needed
}

class Employee {
  final String id;
  final String name;
  final String role;
  final double salary;
  final bool isActive;
  final EmploymentType employmentType;

  Employee({
    required this.id,
    required this.name,
    required this.role,
    required this.salary,
    required this.isActive,
    required this.employmentType,
  });

  factory Employee.fromMap(String id, Map<String, dynamic> data) {
    return Employee(
      id: id,
      name: data['name'],
      role: data['role'],
      salary: (data['salary'] as num).toDouble(),
      isActive: data['isActive'] ?? true,
      employmentType: _parseEmploymentType(data['employmentType']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'role': role,
      'salary': salary,
      'isActive': isActive,
      'employmentType': employmentType.toString().split('.').last,
    };
  }

  static EmploymentType _parseEmploymentType(dynamic value) {
    final String key = (value?.toString() ?? 'fullTime').toLowerCase();

    const Map<String, EmploymentType> mapping = {
      'fulltime': EmploymentType.fullTime,
      'full-time': EmploymentType.fullTime,
      'parttime': EmploymentType.partTime,
      'part-time': EmploymentType.partTime,
      // Add more variations if needed
    };

    return mapping[key] ?? EmploymentType.fullTime; // default fallback
  }
}
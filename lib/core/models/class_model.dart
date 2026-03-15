class ClassModel {
  final String id;
  final String name;
  final double monthlyFee;
  ClassModel({required this.id, required this.name, required this.monthlyFee});

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'monthlyFee': monthlyFee, // ADD THIS LINE
    };
  }

  factory ClassModel.fromMap(Map<String, dynamic> data, String documentId) {
    return ClassModel(
      id: documentId,
      name: data['name'] ?? '',
      monthlyFee:
          (data['monthlyFee'] as num?)?.toDouble() ?? 0.0, // ADD THIS LINE
    );
  }
}

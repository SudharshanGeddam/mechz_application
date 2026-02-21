class ServiceModel {
  final String id;
  final String name;
  final double basePrice;

  ServiceModel({required this.id, required this.name, required this.basePrice});

  factory ServiceModel.fromFirestore(String id, Map<String, dynamic> data) {
    return ServiceModel(
      id: id,
      name: data["name"] ?? "",
      basePrice: (data["basePrice"] ?? 0).toDouble(),
    );
  }
}

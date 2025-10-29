class InventoryItem {
  final String id;
  String name;
  String category;
  String location;
  String? image; // asset filename under assets/img/
  DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.category,
    required this.location,
    this.image,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}

class TrashItem {
  final String id;
  final String name;
  final String placeName;
  final String category;
  final int? quantity;
  final DateTime deletedAt;
  final String originalType; // 'shopping_item', 'alert', etc.
  final Map<String, dynamic>? originalData; // Datos completos para restauración

  TrashItem({
    required this.id,
    required this.name,
    required this.placeName,
    required this.category,
    this.quantity,
    required this.deletedAt,
    required this.originalType,
    this.originalData,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'placeName': placeName,
      'category': category,
      'quantity': quantity,
      'deletedAt': deletedAt.toIso8601String(),
      'originalType': originalType,
      'originalData': originalData,
    };
  }

  factory TrashItem.fromJson(Map<String, dynamic> json) {
    return TrashItem(
      id: json['id'],
      name: json['name'],
      placeName: json['placeName'],
      category: json['category'],
      quantity: json['quantity'],
      deletedAt: DateTime.parse(json['deletedAt']),
      originalType: json['originalType'],
      originalData: json['originalData'] as Map<String, dynamic>?,
    );
  }

  // Crear TrashItem desde ShoppingItem
  factory TrashItem.fromShoppingItem(
    String id,
    String name,
    String placeName,
    String category,
    int? quantity,
  ) {
    return TrashItem(
      id: id,
      name: name,
      placeName: placeName,
      category: category,
      quantity: quantity,
      deletedAt: DateTime.now(),
      originalType: 'shopping_item',
    );
  }
}
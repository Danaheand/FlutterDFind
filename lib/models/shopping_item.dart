class ShoppingItem {
  final String id;
  final String name;
  final String placeName; // lugar_compra
  final String category; // pasillo/categoría
  bool isPurchased;
  DateTime? addedDate;
  int? quantity;
  DateTime? expirationDate;

  ShoppingItem({
    required this.id,
    required this.name,
    required this.placeName,
    required this.category,
    this.isPurchased = false,
    DateTime? addedDate,
    this.quantity,
    this.expirationDate,
  }) : addedDate = addedDate ?? DateTime.now();

  ShoppingItem copyWith({
    String? id,
    String? name,
    String? placeName,
    String? category,
    bool? isPurchased,
    DateTime? addedDate,
    int? quantity,
    DateTime? expirationDate,
  }) {
    return ShoppingItem(
      id: id ?? this.id,
      name: name ?? this.name,
      placeName: placeName ?? this.placeName,
      category: category ?? this.category,
      isPurchased: isPurchased ?? this.isPurchased,
      addedDate: addedDate ?? this.addedDate,
      quantity: quantity ?? this.quantity,
      expirationDate: expirationDate ?? this.expirationDate,
    );
  }
}

class SuggestionItem {
  final String id;
  final String name;
  final String placeName;
  final String category;
  final String reason; // "Stock bajo", "Compra frecuente", etc.
  final String? iconType; // opcional para personalizar el icono

  SuggestionItem({
    required this.id,
    required this.name,
    required this.placeName,
    required this.category,
    required this.reason,
    this.iconType,
  });
}

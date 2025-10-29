enum AlertPriority { low, medium, high }

class AlertItem {
  final String id;
  String title;
  String message;
  DateTime date;
  AlertPriority priority;
  bool active;

  AlertItem({
    required this.id,
    required this.title,
    required this.message,
    DateTime? date,
    this.priority = AlertPriority.medium,
    this.active = true,
  }) : date = date ?? DateTime.now();
}

extension AlertPriorityExt on AlertPriority {
  String get label {
    switch (this) {
      case AlertPriority.low:
        return 'Low';
      case AlertPriority.medium:
        return 'Medium';
      case AlertPriority.high:
        return 'High';
    }
  }
}

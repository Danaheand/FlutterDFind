String formatTime(DateTime date) {
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String formatDateTimeCompact(DateTime date) {
  final day = date.day.toString().padLeft(2, '0');
  final month = date.month.toString().padLeft(2, '0');
  final year = date.year.toString().substring(2);
  final hour = date.hour.toString().padLeft(2, '0');
  final minute = date.minute.toString().padLeft(2, '0');
  return '$day/$month/$year\n$hour:$minute';
}

String formatTimeRemaining(DateTime date) {
  final now = DateTime.now();
  final difference = date.difference(now);

  if (difference.isNegative) {
    final absDiff = difference.abs();
    if (absDiff.inDays > 0) {
      return 'Hace ${absDiff.inDays} día${absDiff.inDays > 1 ? 's' : ''}';
    } else if (absDiff.inHours > 0) {
      return 'Hace ${absDiff.inHours} hora${absDiff.inHours > 1 ? 's' : ''}';
    } else {
      return 'Hace ${absDiff.inMinutes} minuto${absDiff.inMinutes > 1 ? 's' : ''}';
    }
  }

  if (difference.inDays > 0) {
    final hours = difference.inHours % 24;
    return '${difference.inDays} día${difference.inDays > 1 ? 's' : ''} y $hours hora${hours != 1 ? 's' : ''}';
  } else if (difference.inHours > 0) {
    return '${difference.inHours} hora${difference.inHours > 1 ? 's' : ''}';
  } else {
    return '${difference.inMinutes} minuto${difference.inMinutes > 1 ? 's' : ''}';
  }
}

String getMonthName(int month) {
  const months = [
    'Enero',
    'Febrero',
    'Marzo',
    'Abril',
    'Mayo',
    'Junio',
    'Julio',
    'Agosto',
    'Septiembre',
    'Octubre',
    'Noviembre',
    'Diciembre'
  ];
  return months[month - 1];
}

class TimeUtils {
  /// Obtiene el tiempo relativo entre una fecha y ahora
  /// Retorna un mapa con el texto principal, tiempo faltante/pasado y si está vencido
  static Map<String, dynamic> getRelativeTime(DateTime targetDate) {
    final now = DateTime.now();
    final difference = targetDate.difference(now);
    final isPast = difference.isNegative;
    final absDifference = difference.abs();

    String timeText;
    String label;

    if (absDifference.inDays > 0) {
      final days = absDifference.inDays;
      timeText = '$days día${days > 1 ? 's' : ''}';
      label = isPast ? 'PASADOS' : 'FALTAN';
    } else if (absDifference.inHours > 0) {
      final hours = absDifference.inHours;
      timeText = '$hours hora${hours > 1 ? 's' : ''}';
      label = isPast ? 'PASADAS' : 'FALTAN';
    } else if (absDifference.inMinutes > 0) {
      final minutes = absDifference.inMinutes;
      timeText = '$minutes min';
      label = isPast ? 'PASADOS' : 'FALTAN';
    } else {
      timeText = '< 1 min';
      label = isPast ? 'PASADOS' : 'FALTAN';
    }

    return {
      'timeText': timeText,
      'label': label,
      'isPast': isPast,
      'formattedDate': _formatDate(targetDate),
    };
  }

  /// Formatea una fecha en formato "Lun, 19 nov, 18:08"
  static String _formatDate(DateTime date) {
    const monthsShort = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic'
    ];
    const weekdaysShort = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

    final weekday = weekdaysShort[date.weekday - 1];
    final day = date.day;
    final month = monthsShort[date.month - 1];
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');

    return '$weekday, $day $month, $hour:$minute';
  }

  /// Obtiene el texto de frecuencia de repetición legible
  static String getRepeatFrequencyText(String? frequency) {
    if (frequency == null || frequency.isEmpty) return 'No repetitivo';

    switch (frequency.toLowerCase()) {
      case 'diario':
      case 'daily':
        return 'Diario';
      case 'semanal':
      case 'weekly':
        return 'Semanal';
      case 'mensual':
      case 'monthly':
        return 'Mensual';
      case 'anual':
      case 'yearly':
        return 'Anual';
      default:
        return frequency;
    }
  }

  /// Obtiene los nombres cortos de los días de la semana
  static List<String> getWeekdayNames() {
    return ['L', 'M', 'X', 'J', 'V', 'S', 'D'];
  }

  /// Obtiene el nombre completo de un día de la semana
  static String getWeekdayFullName(int index) {
    const names = [
      'Lunes',
      'Martes',
      'Miércoles',
      'Jueves',
      'Viernes',
      'Sábado',
      'Domingo'
    ];
    if (index >= 0 && index < names.length) {
      return names[index];
    }
    return '';
  }
}

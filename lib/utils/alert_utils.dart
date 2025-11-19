import 'package:Dfind/models/alert_data.dart';
import 'package:Dfind/screens/recordatorios_detalle_screen.dart';
import 'package:flutter/material.dart';

Color defaultColorFor(AlertPriority p) {
  switch (p) {
    case AlertPriority.alta:
      return Colors.red.shade400;
    case AlertPriority.media:
      return Colors.amber.shade600;
    case AlertPriority.baja:
      return Colors.blue.shade400;
    default:
      return Colors.blue.shade400;
  }
}

String dateLabel(DateTime date) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final target = DateTime(date.year, date.month, date.day);
  final diff = target.difference(today).inDays;

  if (diff == 0) return 'Hoy';
  if (diff == 1) return 'Mañana';
  if (diff == -1) return 'Ayer';
  if (diff > 1 && diff <= 7) return 'En $diff días';
  if (diff < -1 && diff >= -7) return 'Hace ${diff.abs()} días';
  final d = date.day.toString().padLeft(2, '0');
  final m = date.month.toString().padLeft(2, '0');
  final y = date.year.toString();
  return '$d/$m/$y';
}

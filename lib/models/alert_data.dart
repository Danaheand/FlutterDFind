import 'package:flutter/material.dart';

enum AlertPriority { baja, media, alta }

class AlertData {
  String id;
  String title;
  String description;
  DateTime date;
  AlertPriority priority;
  String? location;
  String? object;
  bool repetitive;
  String? repeatFrequency;
  bool active;
  Color? color;
  String? imagePath;
  List<int>? selectedWeekdays;
  DateTime? createdAt;
  DateTime? updatedAt;

  AlertData({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.priority,
    this.location,
    this.object,
    this.repetitive = false,
    this.repeatFrequency,
    this.active = true,
    this.color,
    this.imagePath,
    this.selectedWeekdays,
    this.createdAt,
    this.updatedAt,
  });
}

typedef DeleteAlertCallback = void Function(AlertData alert);

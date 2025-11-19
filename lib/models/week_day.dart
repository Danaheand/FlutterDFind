class WeekDay {
  final String label;
  final String fullName;
  final int value;

  WeekDay(this.label, this.fullName, this.value);
}

final List<WeekDay> weekDays = [
  WeekDay('L', 'Lunes', 1),
  WeekDay('M', 'Martes', 2),
  WeekDay('X', 'Miércoles', 3),
  WeekDay('J', 'Jueves', 4),
  WeekDay('V', 'Viernes', 5),
  WeekDay('S', 'Sábado', 6),
  WeekDay('D', 'Domingo', 7),
];

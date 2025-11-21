import 'package:flutter/material.dart';
import '../utils/time_utils.dart';

/// Widget que muestra los días de la semana como círculos
/// Permite selección/deselección cuando está en modo edición
class WeekdayIndicator extends StatelessWidget {
  final List<int> selectedWeekdays;
  final bool isEditing;
  final Function(int)? onDayToggle;

  const WeekdayIndicator({
    super.key,
    required this.selectedWeekdays,
    this.isEditing = false,
    this.onDayToggle,
  });

  @override
  Widget build(BuildContext context) {
    final weekdayNames = TimeUtils.getWeekdayNames();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(7, (index) {
        final isSelected = selectedWeekdays.contains(index);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: GestureDetector(
            onTap: isEditing && onDayToggle != null
                ? () => onDayToggle!(index)
                : null,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Theme.of(context).colorScheme.primary // slate-900
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : const Color(0xFF94A3B8), // slate-400
                  width: 2,
                ),
              ),
              child: Center(
                child: Text(
                  weekdayNames[index],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimary
                        : const Color(0xFF64748B), // slate-500
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

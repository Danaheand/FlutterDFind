import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertTabBar extends StatelessWidget {
  final int tabIndex;
  final Function(int) onTabChanged;
  final bool groupByPriority;
  final Function(bool) onGroupByPriorityChanged;

  const AlertTabBar({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
    required this.groupByPriority,
    required this.onGroupByPriorityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          // Tabs: Programado y Historial
          Expanded(
            child: InkWell(
              onTap: () => onTabChanged(0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: tabIndex == 0
                      ? isLight
                          ? Colors.blue.shade50
                          : AppTheme.primaryDark.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Programado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tabIndex == 0
                          ? isLight
                              ? Colors.blue.shade800
                              : AppTheme.primaryDark
                          : isLight
                              ? Colors.black54
                              : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: InkWell(
              onTap: () => onTabChanged(1),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: tabIndex == 1
                      ? isLight
                          ? Colors.blue.shade50
                          : AppTheme.primaryDark.withOpacity(0.2)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Text(
                    'Historial',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: tabIndex == 1
                          ? isLight
                              ? Colors.blue.shade800
                              : AppTheme.primaryDark
                          : isLight
                              ? Colors.black54
                              : Colors.grey[400],
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Botón de toggle de agrupación por prioridad
          InkWell(
            onTap: () => onGroupByPriorityChanged(!groupByPriority),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: groupByPriority
                    ? Colors.blue.shade400
                    : isLight
                        ? Colors.grey.shade200
                        : Colors.grey.shade800,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: groupByPriority
                      ? Colors.blue.shade600
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.sort,
                size: 20,
                color: groupByPriority
                    ? Colors.white
                    : isLight
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

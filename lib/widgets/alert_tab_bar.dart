import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AlertTabBar extends StatelessWidget {
  final int tabIndex;
  final Function(int) onTabChanged;

  const AlertTabBar({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
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
                    'Actuales',
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
                    'Pasadas',
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
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';

class CompactDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const CompactDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.light
            ? Colors.grey.shade50
            : Colors.grey.shade800,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade200
                : Colors.grey.shade700),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon,
              size: 20,
              color: Theme.of(context).brightness == Brightness.light
                  ? Colors.grey.shade600
                  : Colors.grey.shade400),
          const SizedBox(height: 8),
          Consumer<FontSizeProvider>(
            builder: (context, fontSizeProvider, _) => Text(
              label,
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledSize(11),
                fontWeight: FontWeight.w600,
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.grey.shade600
                    : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 6),
          Consumer<FontSizeProvider>(
            builder: (context, fontSizeProvider, _) => Text(
              value,
              style: TextStyle(
                fontSize: fontSizeProvider.getScaledSize(12),
                color: Theme.of(context).brightness == Brightness.light
                    ? Colors.black87
                    : Colors.white,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

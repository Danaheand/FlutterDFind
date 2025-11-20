import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/font_size_provider.dart';

class SimpleDetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const SimpleDetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon,
            size: 22,
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.grey.shade600
                : Colors.grey.shade400),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Consumer<FontSizeProvider>(
                builder: (context, fontSizeProvider, _) => Text(
                  label,
                  style: TextStyle(
                    fontSize: fontSizeProvider.getScaledSize(13),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.light
                        ? Colors.grey.shade600
                        : Colors.grey.shade400,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Consumer<FontSizeProvider>(
                builder: (context, fontSizeProvider, _) => Text(
                  value,
                  style: TextStyle(
                      fontSize: fontSizeProvider.getScaledSize(16),
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black87
                          : Colors.white),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

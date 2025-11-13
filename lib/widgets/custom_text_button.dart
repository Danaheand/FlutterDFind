import 'package:flutter/material.dart';

/// Widget personalizado que actúa como TextButton para evitar conflictos
class CustomTextButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const CustomTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  CustomTextButton.icon({
    super.key,
    required this.onPressed,
    required Widget icon,
    required Widget label,
    this.style,
  }) : child = Row(
          mainAxisSize: MainAxisSize.min,
          children: [icon, const SizedBox(width: 8), label],
        );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final defaultColor = theme.colorScheme.primary;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(4),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: DefaultTextStyle(
            style: TextStyle(
              color: defaultColor,
              fontWeight: FontWeight.w500,
              fontSize: 14,
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}
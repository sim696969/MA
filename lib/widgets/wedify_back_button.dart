import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class WedifyBackButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Color backgroundColor;
  final Color iconColor;
  final String? tooltip;

  const WedifyBackButton({
    super.key,
    this.onPressed,
    this.backgroundColor = AppColors.slate100,
    this.iconColor = AppColors.slate900,
    this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        tooltip: tooltip ?? 'Back',
        icon: Icon(
          Icons.arrow_back_ios_new_rounded,
          size: 18,
          color: iconColor,
        ),
        onPressed: onPressed ?? () => Navigator.maybePop(context),
      ),
    );
  }
}

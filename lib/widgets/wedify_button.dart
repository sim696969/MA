import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum WedifyButtonStyle { primary, outline, ghost, pinkGradient }

class WedifyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final WedifyButtonStyle style;
  final bool isLoading;
  final Widget? icon;
  final Widget? trailingIcon;
  final double? width;
  final double height;

  const WedifyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = WedifyButtonStyle.primary,
    this.isLoading = false,
    this.icon,
    this.trailingIcon,
    this.width,
    this.height = 54,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (style == WedifyButtonStyle.pinkGradient) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            colors: [AppColors.pinkGradientStart, AppColors.pinkGradientEnd],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(24),
            child: Center(
              child: _buildContent(Colors.white),
            ),
          ),
        ),
      );
    }

    switch (style) {
      case WedifyButtonStyle.primary:
        return SizedBox(
          width: width,
          height: height,
          child: ElevatedButton(
            onPressed: isLoading ? null : onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinkPrimary,
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: _buildContent(Colors.white),
          ),
        );
      case WedifyButtonStyle.outline:
        return SizedBox(
          width: width,
          height: height,
          child: OutlinedButton(
            onPressed: isLoading ? null : onPressed,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.borderLight),
              shape: const StadiumBorder(),
              foregroundColor: AppColors.slate900,
            ),
            child: _buildContent(theme.colorScheme.onSurface),
          ),
        );
      case WedifyButtonStyle.ghost:
        return SizedBox(
          width: width,
          height: height,
          child: TextButton(
            onPressed: isLoading ? null : onPressed,
            style: TextButton.styleFrom(
              shape: const StadiumBorder(),
              foregroundColor: AppColors.slate700,
            ),
            child: _buildContent(theme.colorScheme.onSurface),
          ),
        );
      default:
        return Container();
    }
  }

  Widget _buildContent(Color color) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      );
    }
    
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon != null) ...[
          icon!,
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        if (trailingIcon != null) ...[
          const SizedBox(width: 8),
          trailingIcon!,
        ],
      ],
    );
  }
}

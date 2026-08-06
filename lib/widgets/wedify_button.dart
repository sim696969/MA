import 'package:flutter/material.dart';

enum WedifyButtonStyle { primary, outline, ghost }

class WedifyButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final WedifyButtonStyle style;
  final bool isLoading;
  final Widget? icon;

  const WedifyButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.style = WedifyButtonStyle.primary,
    this.isLoading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    switch (style) {
      case WedifyButtonStyle.primary:
        return ElevatedButton(
          onPressed: isLoading ? null : onPressed,
          child: _buildContent(theme.colorScheme.onPrimary),
        );
      case WedifyButtonStyle.outline:
        return OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: theme.colorScheme.outline),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            foregroundColor: theme.colorScheme.onBackground,
          ),
          child: _buildContent(theme.colorScheme.onBackground),
        );
      case WedifyButtonStyle.ghost:
        return TextButton(
          onPressed: isLoading ? null : onPressed,
          style: TextButton.styleFrom(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            foregroundColor: theme.colorScheme.onBackground,
          ),
          child: _buildContent(theme.colorScheme.onBackground),
        );
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
        Text(text),
      ],
    );
  }
}

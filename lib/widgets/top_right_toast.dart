import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// The app-level messenger makes notifications survive route and bottom-sheet
/// changes, so a completed action can always report its result.
final GlobalKey<ScaffoldMessengerState> appScaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

enum ToastType { success, error, info, warning }

/// Shows a repeatable notification for a completed user action.
///
/// This deliberately uses [ScaffoldMessenger] instead of retaining custom
/// overlay state. The messenger queues each call, so feedback for one action
/// never prevents a later action from reporting its result.
void showBlackAndWhiteSnackbar(
  BuildContext context,
  String message, {
  ToastType type = ToastType.success,
}) {
  final messenger = ScaffoldMessenger.maybeOf(context) ??
      appScaffoldMessengerKey.currentState;
  if (messenger == null) return;

  messenger.showSnackBar(
    SnackBar(
      backgroundColor:
          type == ToastType.success ? AppColors.sage : AppColors.navy,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 3),
      content: Text(
        message,
        style: const TextStyle(color: Colors.white),
      ),
    ),
  );
}

extension ToastX on BuildContext {
  void showTopRightToast({
    required String message,
    ToastType type = ToastType.success,
    Duration duration = const Duration(seconds: 3),
  }) {
    showBlackAndWhiteSnackbar(this, message, type: type);
  }

  void showTopRightSuccess(String message) =>
      showBlackAndWhiteSnackbar(this, message, type: ToastType.success);
  void showTopRightError(String message) =>
      showBlackAndWhiteSnackbar(this, message, type: ToastType.error);
  void showTopRightInfo(String message) =>
      showBlackAndWhiteSnackbar(this, message, type: ToastType.info);
  void showTopRightWarning(String message) =>
      showBlackAndWhiteSnackbar(this, message, type: ToastType.warning);
}

/// Kept as a no-op wrapper to avoid changing the app's composition.
class TopRightToastWrapper extends StatelessWidget {
  final Widget child;

  const TopRightToastWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) => child;
}

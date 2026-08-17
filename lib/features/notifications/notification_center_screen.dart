import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_provider.dart';
import '../../services/wedding_project_provider.dart';
import '../checkout/checkout_screen.dart';

class NotificationCenterScreen extends ConsumerWidget {
  const NotificationCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationProvider);
    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: AppColors.warmCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 56,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8),
          child: IconButton(
            tooltip: 'Back to dashboard',
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.navy,
              size: 22,
            ),
          ),
        ),
        title: const Text(
          'Notifications',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
            onPressed: notifications.isEmpty
                ? null
                : () => ref.read(notificationProvider.notifier).markAllRead(),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blush,
                disabledBackgroundColor: AppColors.slate300,
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.done_all_rounded, size: 15),
              label: const Text('Mark all read'),
            ),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const Center(
              child: Text(
                'You are all caught up.',
                style: TextStyle(color: AppColors.slate500),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) => _NotificationCard(
                notification: notifications[index],
                onTap: () => _handleNotificationTap(
                  context,
                  ref,
                  notifications[index],
                ),
              ),
            ),
    );
  }

  Future<void> _handleNotificationTap(
    BuildContext context,
    WidgetRef ref,
    NotificationModel notification,
  ) async {
    await ref.read(notificationProvider.notifier).markRead(notification.id);
    if (!context.mounted) return;

    if (notification.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This action has already been completed.')),
      );
      return;
    }

    final project = ref.read(weddingProjectProvider);
    switch (notification.targetRoute) {
      case notificationRouteCheckout:
        if (project.isPaid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('This action has already been completed.')),
          );
        } else {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
          );
        }
      case notificationRouteReceipt:
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CheckoutScreen()),
        );
      case notificationRouteSupport:
        await showDialog<void>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: const Text('Refund Processing'),
            content: const Text(
              'Our support team will contact you by email regarding your refund. No action is required at this time.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      case notificationRouteDashboard:
        Navigator.pop(context);
    }
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = notification.isExpired
        ? 'EXPIRED'
        : notification.isRead
            ? 'READ'
            : 'UNREAD';
    final badgeColor = notification.isExpired
        ? AppColors.slate400
        : notification.isRead
            ? AppColors.slate500
            : AppColors.blush;
    return Opacity(
      opacity: notification.isExpired ? 0.6 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: notification.isRead
                    ? AppColors.borderLight
                    : AppColors.blush,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        notification.title,
                        style: const TextStyle(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    _StatusBadge(label: status, color: badgeColor),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  notification.body,
                  style: const TextStyle(color: AppColors.slate600, height: 1.4),
                ),
                const SizedBox(height: 10),
                Text(
                  _timeAgo(notification.createdAt),
                  style: const TextStyle(color: AppColors.slate500, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _timeAgo(DateTime value) {
    final difference = DateTime.now().difference(value);
    if (difference.inMinutes < 1) return 'Just now';
    if (difference.inHours < 1) return '${difference.inMinutes} minutes ago';
    if (difference.inDays < 1) return '${difference.inHours} hours ago';
    return '${difference.inDays} days ago';
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

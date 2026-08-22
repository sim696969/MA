import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../models/notification_model.dart';
import '../../services/notification_provider.dart';
import '../../services/wedding_project_provider.dart';
import '../../widgets/wedify_back_button.dart';
import '../checkout/checkout_screen.dart';

class NotificationCenterScreen extends ConsumerStatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  ConsumerState<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState
    extends ConsumerState<NotificationCenterScreen> {
  final Set<String> _selectedIds = {};
  bool _isSelecting = false;

  void _toggleSelectionMode() {
    setState(() {
      _isSelecting = !_isSelecting;
      _selectedIds.clear();
    });
  }

  void _toggleSelect(String id) {
    setState(() {
      if (_selectedIds.contains(id)) {
        _selectedIds.remove(id);
      } else {
        _selectedIds.add(id);
      }
    });
  }

  void _selectAll(List<NotificationModel> notifications) {
    setState(() {
      _selectedIds.addAll(notifications.map((n) => n.id));
    });
  }

  Future<void> _deleteSelected() async {
    if (_selectedIds.isEmpty) return;
    final confirmed = await _showDeleteConfirmDialog(
      _selectedIds.length == 1
          ? 'Delete this notification?'
          : 'Delete ${_selectedIds.length} notifications?',
    );
    if (!confirmed || !mounted) return;

    final notifier = ref.read(notificationProvider.notifier);
    for (final id in List<String>.from(_selectedIds)) {
      await notifier.deleteNotification(id);
    }
    if (mounted) {
      setState(() {
        _selectedIds.clear();
        _isSelecting = false;
      });
    }
  }

  Future<void> _deleteAll(List<NotificationModel> notifications) async {
    final confirmed = await _showDeleteConfirmDialog(
      'Delete all ${notifications.length} notifications?',
    );
    if (!confirmed || !mounted) return;
    await ref.read(notificationProvider.notifier).clearAllNotifications();
    if (mounted) {
      setState(() {
        _selectedIds.clear();
        _isSelecting = false;
      });
    }
  }

  Future<bool> _showDeleteConfirmDialog(String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Confirm Delete',
              style: TextStyle(
                  color: AppColors.navy, fontWeight: FontWeight.w800),
            ),
            content: Text(message,
                style: const TextStyle(color: AppColors.slate600)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel',
                    style: TextStyle(color: AppColors.slate500)),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Delete'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _handleNotificationTap(NotificationModel notification) async {
    if (_isSelecting) {
      _toggleSelect(notification.id);
      return;
    }

    await ref.read(notificationProvider.notifier).markRead(notification.id);
    if (!mounted) return;

    // Invitation notifications: show invitation dialog popup
    if (notification.id.startsWith('invitation_')) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.blush, width: 1.5),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.pinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.pinkPrimary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 10),
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
            ],
          ),
          content: Text(
            notification.body,
            style: const TextStyle(
              color: AppColors.slate700,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blush,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Viewed & Accepted'),
            ),
          ],
        ),
      );
      return;
    }

    // Cancellation notifications: show detail popup, remain as read (no auto-delete)
    if (notification.id.startsWith('cancellation_')) {
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Text('❌  ', style: TextStyle(fontSize: 20)),
              Text(
                'Project Canceled',
                style: TextStyle(
                    color: AppColors.navy, fontWeight: FontWeight.w800),
              ),
            ],
          ),
          content: const Text(
            'Your wedding project and all associated bookings have been '
            'canceled and reset. You can start a fresh plan anytime from the home screen.',
            style: TextStyle(color: AppColors.slate600, height: 1.5),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.blush,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Got it'),
            ),
          ],
        ),
      );
      return;
    }

    if (notification.isExpired) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('This action has already been completed.')),
      );
      return;
    }

    final project = ref.read(weddingProjectProvider);
    switch (notification.targetRoute) {
      case notificationRouteCheckout:
        if (project.isPaid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('This action has already been completed.')),
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
            backgroundColor: Colors.white,
            surfaceTintColor: Colors.transparent,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text(
              'Refund Processing',
              style: TextStyle(color: AppColors.navy, fontWeight: FontWeight.w800),
            ),
            content: const Text(
              'Our support team will contact you by email regarding your '
              'refund. No action is required at this time.',
              style: TextStyle(color: AppColors.slate600, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Close', style: TextStyle(color: AppColors.slate500)),
              ),
            ],
          ),
        );
      case notificationRouteDashboard:
        if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(notificationProvider);

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      appBar: AppBar(
        backgroundColor: AppColors.warmCream,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leadingWidth: 64,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: _isSelecting
                ? Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Cancel selection',
                      onPressed: _toggleSelectionMode,
                      icon: const Icon(Icons.close_rounded,
                          color: AppColors.slate900, size: 20),
                    ),
                  )
                : WedifyBackButton(
                    tooltip: 'Back to dashboard',
                    onPressed: () => Navigator.maybePop(context),
                  ),
          ),
        ),
        title: Text(
          _isSelecting ? '${_selectedIds.length} selected' : 'Notifications',
          style: const TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        actions: _isSelecting
            ? [
                if (_selectedIds.length < notifications.length)
                  TextButton(
                    onPressed: () => _selectAll(notifications),
                    child: const Text('All',
                        style: TextStyle(
                            color: AppColors.blush,
                            fontWeight: FontWeight.w700)),
                  ),
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: IconButton(
                    tooltip: 'Delete selected',
                    onPressed: _selectedIds.isEmpty ? null : _deleteSelected,
                    icon: Icon(
                      Icons.delete_rounded,
                      color: _selectedIds.isEmpty
                          ? AppColors.slate400
                          : Colors.red,
                    ),
                  ),
                ),
              ]
            : [
                if (notifications.isNotEmpty)
                  IconButton(
                    tooltip: 'Mark all read',
                    onPressed: () =>
                        ref.read(notificationProvider.notifier).markAllRead(),
                    icon: const Icon(Icons.done_all_rounded,
                        color: AppColors.blush),
                  ),
                if (notifications.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: IconButton(
                      tooltip: 'Select to delete',
                      onPressed: _toggleSelectionMode,
                      icon: const Icon(Icons.delete_sweep_rounded,
                          color: AppColors.navy),
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
          : Column(
              children: [
                if (_isSelecting)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _deleteAll(notifications),
                        icon: const Icon(Icons.delete_forever_rounded,
                            size: 18, color: Colors.red),
                        label: const Text('Delete All',
                            style: TextStyle(color: Colors.red)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: notifications.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final n = notifications[index];
                      return _NotificationCard(
                        notification: n,
                        isSelecting: _isSelecting,
                        isSelected: _selectedIds.contains(n.id),
                        onTap: () => _handleNotificationTap(n),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback onTap;
  final bool isSelecting;
  final bool isSelected;

  const _NotificationCard({
    required this.notification,
    required this.onTap,
    required this.isSelecting,
    required this.isSelected,
  });

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
        color: isSelected ? AppColors.blush.withValues(alpha: 0.08) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected
                    ? AppColors.blush
                    : notification.isRead
                        ? AppColors.borderLight
                        : AppColors.blush,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (isSelecting)
                  Padding(
                    padding: const EdgeInsets.only(right: 12, top: 2),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.blush : Colors.transparent,
                        border: Border.all(
                          color:
                              isSelected ? AppColors.blush : AppColors.slate400,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : null,
                    ),
                  ),
                Expanded(
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
                        style: const TextStyle(
                            color: AppColors.slate600, height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _timeAgo(notification.createdAt),
                        style: const TextStyle(
                            color: AppColors.slate500, fontSize: 12),
                      ),
                    ],
                  ),
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
      decoration: BoxDecoration(
          color: color, borderRadius: BorderRadius.circular(20)),
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

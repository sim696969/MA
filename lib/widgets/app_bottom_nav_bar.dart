import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../services/notification_provider.dart';
import '../features/home/home_screen.dart';
import '../features/notifications/notification_center_screen.dart';
import '../features/auth/user_profile_screen.dart';

class WedifyBottomNavigationBar extends ConsumerWidget {
  final int currentIndex;

  const WedifyBottomNavigationBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: AppColors.navy,
        border: Border(top: BorderSide(color: AppColors.navy)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(
            context: context,
            index: 0,
            icon: Icons.home_outlined,
            activeIcon: Icons.home_rounded,
            showDot: true,
          ),
          _buildNavItem(
            context: context,
            index: 1,
            icon: Icons.notifications_none_rounded,
            activeIcon: Icons.notifications_rounded,
            unreadCount: unreadCount,
          ),
          _buildNavItem(
            context: context,
            index: 2,
            icon: Icons.person_outline_rounded,
            activeIcon: Icons.person_rounded,
            showDot: true,
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required int index,
    required IconData icon,
    required IconData activeIcon,
    bool showDot = false,
    int unreadCount = 0,
  }) {
    final isSelected = currentIndex == index;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (currentIndex == index) return;

        if (index == 0) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const HomeScreen()),
            (route) => false,
          );
        } else if (index == 1) {
          if (currentIndex == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const NotificationCenterScreen(),
              ),
            );
          }
        } else if (index == 2) {
          if (currentIndex == 0) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const UserProfileScreen(),
              ),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => const UserProfileScreen(),
              ),
            );
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? AppColors.pinkPrimary : Colors.white70,
                size: 26,
              ),
              if (unreadCount > 0)
                Positioned(
                  right: -8,
                  top: -8,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE57373),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unreadCount > 99 ? '99+' : '$unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          if (showDot && isSelected) ...[
            const SizedBox(height: 4),
            Container(
              width: 5,
              height: 5,
              decoration: const BoxDecoration(
                color: AppColors.pinkPrimary,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

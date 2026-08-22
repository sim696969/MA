import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../models/wedding_project_model.dart';
import '../../services/wedding_project_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../../widgets/wedify_back_button.dart';
import '../home/home_screen.dart';
import '../venue/venue_finder_screen.dart';
import '../planner/layout_planner_screen.dart';
import '../invitation/invitation_gallery_screen.dart';
import '../catering/catering_selector_screen.dart';
import '../checkout/checkout_screen.dart';

class FeaturesHubScreen extends ConsumerWidget {
  const FeaturesHubScreen({super.key});

  Future<void> _handleInvitationChoice(
    BuildContext context,
    WidgetRef ref,
    Widget screen,
  ) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.pinkBorder, width: 1.5),
        ),
        title: Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: const BoxDecoration(
                  color: AppColors.pinkLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_rounded,
                  color: AppColors.pinkPrimary,
                  size: 28,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                "Invitation Options",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
              ),
            ],
          ),
        ),
        content: const Text(
          "How would you like to invite your guests?\n\nChoose digital invitations for email/RSVP tracking, or skip if you're using printed cards or word-of-mouth.",
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.slate700,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
        actions: [
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(dialogCtx, 'physical'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.sage, width: 1.5),
                foregroundColor: AppColors.sage,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              icon: const Icon(Icons.how_to_reg_rounded, size: 18),
              label: const Text(
                "Use Physical Invitations",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => Navigator.pop(dialogCtx, 'digital'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
              ),
              icon: const Icon(Icons.email_rounded, size: 18),
              label: const Text(
                "Browse Digital Invitations",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );

    if (!context.mounted) return;

    if (choice == 'physical') {
      final result = await ref
          .read(weddingProjectProvider.notifier)
          .optOutOfInvitation();
      if (!context.mounted) return;
      if (result.type == PaymentModificationType.refundDue) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.sage,
            content: Text(
              'Refund of RM ${result.amount.toStringAsFixed(2)} will be processed.',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.sage,
            content: Text(
              'Invitation step marked as Physical Invitations (RM 0).',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        );
      }
    } else if (choice == 'digital') {
      final result = await Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => screen),
      );
      if (result != null && result is Map<String, dynamic> && context.mounted) {
        ref
            .read(weddingProjectProvider.notifier)
            .updateInvitation(
              invitationName:
                  result['invitationName'] as String? ?? "Selected Invitation",
              fee: (result['fee'] as num?)?.toDouble() ?? 0.0,
            );
      }
    }
  }

  void _handleFeatureClick(
    BuildContext context,
    WidgetRef ref,
    WeddingProject project,
    Widget screen,
    String featureTitle,
  ) async {
    if (!project.isInitialized) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: AppColors.pinkPrimary),
              SizedBox(width: 10),
              Text(
                "Feature Locked",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            "Please start your Wedding Project and set a Date & Time first on the Home page before accessing $featureTitle.",
            style: const TextStyle(
              color: AppColors.slate700,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
              },
              child: const Text(
                "Cancel",
                style: TextStyle(color: AppColors.slate700),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HomeScreen(),
                  ),
                  (route) => false,
                );
              },
              child: const Text(
                "Set Time",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    if (featureTitle == "Digital Invitations") {
      _handleInvitationChoice(context, ref, screen);
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    if (result != null) {
      if (featureTitle == "Venue Finder" && result is Map<String, dynamic>) {
        // VenueFinder handles booking persistence internally
      } else if (featureTitle == "2D Planner" &&
          result is Map<String, dynamic>) {
        ref
            .read(weddingProjectProvider.notifier)
            .updatePlannerLayout(
              layoutSummary:
                  result['layoutSummary'] as String? ?? "Custom Layout",
              fee: (result['fee'] as num?)?.toDouble() ?? 800.0,
            );
      } else if (featureTitle == "Invitations" &&
          result is Map<String, dynamic>) {
        ref
            .read(weddingProjectProvider.notifier)
            .updateInvitation(
              invitationName:
                  result['invitationName'] as String? ?? "Selected Invitation",
              fee: (result['fee'] as num?)?.toDouble() ?? 0.0,
            );
      } else if (featureTitle == "F&B Catering" &&
          result is Map<String, dynamic>) {
        ref
            .read(weddingProjectProvider.notifier)
            .updateCatering(
              cateringPackage:
                  result['cateringPackage'] as String? ?? "Selected Package",
              fee: (result['fee'] as num?)?.toDouble() ?? 5500.0,
            );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final project = ref.watch(weddingProjectProvider);

    final invitationDone =
        project.isInvitationCompleted || project.invitationOptedOut;
    final invitationInfo = project.invitationOptedOut
        ? "Physical Invitations (Self-Managed)"
        : project.selectedInvitationName;

    final features = [
      _FeatureCardData(
        title: "Venue Finder",
        subtitle: "Find & book your dream location",
        icon: Icons.apartment_rounded,
        screen: const VenueFinderScreen(),
        isCompleted: project.isVenueCompleted,
        selectedInfo: project.selectedVenueName,
      ),
      _FeatureCardData(
        title: "2D Layout Planner",
        subtitle: "Design & arrange seating layouts",
        icon: Icons.architecture_rounded,
        screen: const LayoutPlannerScreen(),
        isCompleted: project.isPlannerCompleted,
        selectedInfo: project.plannerLayoutSummary,
      ),
      _FeatureCardData(
        title: "Digital Invitations",
        subtitle: project.invitationOptedOut
            ? "Using physical / printed invitations"
            : "Pick e-invites & track RSVPs",
        icon: Icons.mark_email_unread_rounded,
        screen: const InvitationGalleryScreen(),
        isCompleted: invitationDone,
        selectedInfo: invitationInfo,
        isOptedOut: project.invitationOptedOut,
      ),
      _FeatureCardData(
        title: "F&B Catering",
        subtitle: "Select menus & dining packages",
        icon: Icons.cake_rounded,
        screen: const CateringSelectorScreen(),
        isCompleted: project.isCateringCompleted,
        selectedInfo: project.selectedCateringPackage,
      ),
    ];

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
            child: WedifyBackButton(
              tooltip: 'Back to dashboard',
              onPressed: () => Navigator.maybePop(context),
            ),
          ),
        ),
        title: const Text(
          'Wedding Features',
          style: TextStyle(
            color: AppColors.navy,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Explore Features",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              "Manage and set up all core parts of your wedding celebration.",
              style: TextStyle(fontSize: 13, color: AppColors.slate500),
            ),
            const SizedBox(height: 20),

            // Planning Progress & Checkout Card
            if (project.isInitialized) ...[
              _buildProgressAndCheckoutCard(context, project),
              const SizedBox(height: 20),
            ],

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: features.length,
              separatorBuilder: (_, __) => const SizedBox(height: 14),
              itemBuilder: (context, index) {
                final feature = features[index];
                final isUnlocked = project.isInitialized;

                return GestureDetector(
                  onTap: () => _handleFeatureClick(
                    context,
                    ref,
                    project,
                    feature.screen,
                    feature.title,
                  ),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: feature.isCompleted
                            ? AppColors.pinkPrimary
                            : AppColors.slate200,
                        width: feature.isCompleted ? 1.5 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: feature.isCompleted
                                ? AppColors.pinkLight
                                : AppColors.slate100,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            feature.icon,
                            color: feature.isCompleted
                                ? AppColors.pinkPrimary
                                : AppColors.slate700,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    feature.title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  if (feature.isOptedOut ?? false)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F0E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "PHYSICAL",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.sage,
                                        ),
                                      ),
                                    )
                                  else if (feature.isCompleted)
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE3F0E9),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: const Text(
                                        "DONE",
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.sage,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                feature.subtitle,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.slate500,
                                ),
                              ),
                              if (feature.selectedInfo?.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "Selected: ${feature.selectedInfo}",
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.pinkPrimary,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        Icon(
                          !isUnlocked
                              ? Icons.lock_rounded
                              : Icons.chevron_right_rounded,
                          color: !isUnlocked
                              ? AppColors.slate400
                              : AppColors.slate700,
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: const WedifyBottomNavigationBar(currentIndex: 1),
    );
  }

  Widget _buildProgressAndCheckoutCard(
    BuildContext context,
    WeddingProject project,
  ) {
    final percentInt = (project.progressPercentage * 100).toInt();
    final isPaid = project.isPaid;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Checkout & Booking",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isPaid
                        ? "Booking confirmed & paid"
                        : "${project.completedStepsCount} of 4 steps completed",
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: isPaid
                      ? AppColors.sage
                      : (project.isFullyCompleted
                            ? AppColors.pinkPrimary
                            : Colors.white.withValues(alpha: 0.15)),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  isPaid ? "PAID" : "$percentInt%",
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: project.progressPercentage,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: isPaid ? AppColors.sage : AppColors.pinkPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Action Button
          SizedBox(
            width: double.infinity,
            height: 46,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: isPaid
                    ? AppColors.sage
                    : AppColors.pinkPrimary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CheckoutScreen(),
                  ),
                );
              },
              icon: Icon(
                isPaid
                    ? Icons.receipt_long_rounded
                    : Icons.shopping_bag_rounded,
                size: 18,
              ),
              label: Text(
                isPaid ? "View Receipt & Order Details" : "Proceed to Checkout",
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCardData {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget screen;
  final bool isCompleted;
  final String? selectedInfo;
  final bool? isOptedOut;

  _FeatureCardData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.screen,
    required this.isCompleted,
    this.selectedInfo,
    this.isOptedOut,
  });
}

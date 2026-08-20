import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../models/wedding_project_model.dart';
import '../../services/wedding_project_provider.dart';
import '../../services/catering_cart_provider.dart';
import '../auth/auth_screen.dart';
import '../venue/venue_finder_screen.dart';
import '../planner/layout_planner_screen.dart';
import '../invitation/invitation_gallery_screen.dart';
import '../catering/catering_selector_screen.dart';
import '../checkout/checkout_screen.dart';
import '../../services/auth_session_service.dart';
import '../notifications/notification_center_screen.dart';
import '../../services/notification_provider.dart';
import '../../widgets/top_right_toast.dart';
import '../../widgets/app_bottom_nav_bar.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedCalendarDay;

  // ────────────────────────────────────────────────────────────────────────────
  // Centralized Complete Booking Reset.
  // Wipes in-memory state + Firestore subcollections + local cache.
  // Called only by: Cancel Wedding Project.
  // ────────────────────────────────────────────────────────────────────────────
  Future<void> _resetAllBookingState() async {
    // 1. Clear in-memory catering cart FIRST (fast, synchronous)
    ref.read(cateringCartProvider.notifier).clearCart();

    // 2. Reset local calendar/dashboard UI state so progress instantly shows 0%
    if (mounted) {
      setState(() {
        _focusedDay = DateTime.now();
        _selectedCalendarDay = null;
      });
    }

    // 3. Deep full reset: deletes Firestore subcollections (guests, catering orders,
    //    layouts, invitations), wipes SharedPreferences, resets Riverpod project state.
    await ref.read(weddingProjectProvider.notifier).fullResetAllBookingData();

    // 4. Create a cancellation notification for the user
    await ref.read(notificationProvider.notifier).addCancellationNotification();
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Logout",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.slate900,
          ),
        ),
        content: const Text(
          "Are you sure you want to log out of Wedify?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              "Cancel",
              style: TextStyle(color: AppColors.slate600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinkPrimary,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  // Dialog to confirm and cancel entire wedding project
  Future<void> _showCancelWeddingDialog() async {
    final shouldCancel = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Colors.black, width: 2),
        ),
        titlePadding: const EdgeInsets.fromLTRB(22, 22, 22, 0),
        contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 0),
        actionsPadding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              "Cancel Wedding Project?",
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
                fontSize: 16,
                color: Colors.black,
              ),
            ),
          ],
        ),
        content: Text(
          "Are you sure you want to cancel your entire wedding booking? This will permanently delete your venue, planner, invitations, and catering selections. This action cannot be undone.",
          style: GoogleFonts.inter(
            fontSize: 13,
            color: Colors.black87,
            height: 1.45,
          ),
        ),
        actions: [
          Row(
            children: [
              // Keep Booking (Dismiss)
              TextButton(
                onPressed: () => Navigator.of(dialogCtx).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.black54,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 8,
                  ),
                ),
                child: Text(
                  "Keep Booking",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.black54,
                  ),
                ),
              ),
              const Spacer(),
              // Yes, Cancel (Destructive)
              ElevatedButton(
                onPressed: () => Navigator.of(dialogCtx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  "Yes, Cancel",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );

    if (shouldCancel == true && mounted) {
      // Call centralized COMPLETE reset — wipes catering cart + all Firestore
      // subcollections (guests, catering orders, layouts, invitations) + all
      // local state + SharedPreferences.
      await _resetAllBookingState();
      if (!mounted) return;
      context.showTopRightSuccess(
        "Wedding project has been completely reset. All selections were cleared.",
      );
    }
  }

  // Dialog to prompt user to select date and time
  Future<void> _showStartProjectModal(
    BuildContext context,
    WeddingProject project,
  ) async {
    DateTime selectedDate =
        project.weddingDate ?? DateTime.now().add(const Duration(days: 90));
    TimeOfDay selectedTime = const TimeOfDay(hour: 11, minute: 0);

    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.pinkLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      color: AppColors.pinkPrimary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Wedding Schedule",
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: AppColors.slate900,
                    ),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please select your planned Wedding Date and Time to initialize feature access.",
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.slate600,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Date Picker Card
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(
                          const Duration(days: 1095),
                        ),
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.pinkPrimary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: AppColors.slate900,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.pinkPrimary,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              datePickerTheme: DatePickerThemeData(
                                backgroundColor: Colors.white,
                                dayForegroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return Colors.white;
                                      }
                                      return AppColors.slate900;
                                    }),
                                dayBackgroundColor:
                                    WidgetStateProperty.resolveWith((states) {
                                      if (states.contains(
                                        WidgetState.selected,
                                      )) {
                                        return AppColors.pinkPrimary;
                                      }
                                      return Colors.transparent;
                                    }),
                                confirmButtonStyle: TextButton.styleFrom(
                                  foregroundColor: AppColors.pinkPrimary,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                cancelButtonStyle: TextButton.styleFrom(
                                  foregroundColor: AppColors.slate600,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedDate != null) {
                        setModalState(() => selectedDate = pickedDate);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate100.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.pinkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: AppColors.pinkPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Wedding Date",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                  Text(
                                    DateFormat(
                                      'MMM dd, yyyy',
                                    ).format(selectedDate),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.slate400,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Time Picker Card
                  InkWell(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                        builder: (BuildContext context, Widget? child) {
                          return Theme(
                            data: Theme.of(context).copyWith(
                              colorScheme: const ColorScheme.light(
                                primary: AppColors.pinkPrimary,
                                onPrimary: Colors.white,
                                surface: Colors.white,
                                onSurface: AppColors.slate900,
                                primaryContainer: AppColors.pinkLight,
                                onPrimaryContainer: AppColors.pinkPrimary,
                              ),
                              textButtonTheme: TextButtonThemeData(
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.pinkPrimary,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              timePickerTheme: TimePickerThemeData(
                                backgroundColor: Colors.white,
                                hourMinuteTextColor: AppColors.slate900,
                                hourMinuteColor: AppColors.slate100,
                                dayPeriodTextColor: AppColors.slate900,
                                dayPeriodColor: AppColors.slate100,
                                dialHandColor: AppColors.pinkPrimary,
                                dialBackgroundColor: AppColors.slate100,
                                dialTextColor: AppColors.slate900,
                                entryModeIconColor: AppColors.pinkPrimary,
                                confirmButtonStyle: TextButton.styleFrom(
                                  foregroundColor: AppColors.pinkPrimary,
                                  textStyle: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                cancelButtonStyle: TextButton.styleFrom(
                                  foregroundColor: AppColors.slate600,
                                ),
                              ),
                            ),
                            child: child!,
                          );
                        },
                      );
                      if (pickedTime != null) {
                        setModalState(() => selectedTime = pickedTime);
                      }
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.slate100.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.pinkBorder),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: AppColors.pinkPrimary,
                                size: 20,
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Event Time",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.slate500,
                                    ),
                                  ),
                                  Text(
                                    selectedTime.format(context),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.slate900,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppColors.slate400,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: AppColors.slate600),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text(
                    "Start Project",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );

    if (isConfirmed == true && context.mounted) {
      final formattedTime = selectedTime.format(context);
      ref
          .read(weddingProjectProvider.notifier)
          .setDateTime(selectedDate, formattedTime);
      context.showTopRightSuccess(
        "Wedding Project started for ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $formattedTime!",
      );
    }
  }

  void _handleFeatureClick(
    BuildContext context,
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
            "Please start your Wedding Project and set a Date & Time first before accessing $featureTitle.",
            style: const TextStyle(
              color: AppColors.slate700,
              fontSize: 13,
              height: 1.4,
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showStartProjectModal(context, project);
              },
              child: const Text(
                "Set Date & Time",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => screen),
    );

    // ONLY update step completion if user actually made a selection (result != null)
    // Never overwrite existing data with hardcoded defaults if user just pressed back
    if (result != null) {
      if (featureTitle == "Venue Finder" && result is Map<String, dynamic>) {
        // VenueFinder persists the reservation before returning. Do not save a
        // second time here, where an old route could hold stale project state.
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
              fee: (result['fee'] as num?)?.toDouble() ?? 650.0,
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
  Widget build(BuildContext context) {
    final project = ref.watch(weddingProjectProvider);
    final unreadCount = ref.watch(unreadNotificationCountProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row: Notification (Top Left) & Logout (Top Right)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Notification Bell Button with live Unread Badge (Top Left)
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          tooltip: 'Notifications',
                          icon: const Icon(
                            Icons.notifications_none_rounded,
                            color: AppColors.slate900,
                            size: 22,
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const NotificationCenterScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      if (unreadCount > 0)
                        Positioned(
                          top: -4,
                          right: -4,
                          child: Container(
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            padding: const EdgeInsets.all(3),
                            decoration: const BoxDecoration(
                              color: AppColors.pinkPrimary,
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                unreadCount > 99 ? '99+' : '$unreadCount',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  // Logout Button (Top Right)
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      tooltip: 'Logout',
                      icon: const Icon(
                        Icons.logout_rounded,
                        color: AppColors.pinkPrimary,
                        size: 20,
                      ),
                      onPressed: () => _handleLogout(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Hero Action: Prominent "Start a Wedding Project" Button
              _buildMainActionBanner(context, project),
              const SizedBox(height: 24),

              if (project.isVenueCompleted &&
                  project.selectedVenueName?.isNotEmpty == true) ...[
                _buildBookedVenueCard(context, project),
                const SizedBox(height: 16),
              ],

              if (project.amountPaid > 0 && project.balanceDue > 0) ...[
                _buildPaymentIncompleteBanner(context, project),
                const SizedBox(height: 16),
              ],

              // 3. Progress Indicator Card
              _buildProgressCard(context, project),
              const SizedBox(height: 28),

              // 4. 4 Features Buttons Grid (Venue, 2D Planner, Invitations, F&B Catering)
              const Text(
                "Wedding Services",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.slate900,
                ),
              ),
              const SizedBox(height: 14),
              _buildFourFeaturesGrid(context, project),
              const SizedBox(height: 32),

              // 5. Checkout Banner if 100% complete
              if (project.isFullyCompleted) ...[
                _buildCheckoutBanner(context, project),
                const SizedBox(height: 28),
              ],

              // 6. Calendar Integration (Replaces Recent Events)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Booking Calendar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  Text(
                    project.weddingDate != null ? "Date Saved" : "Select Date",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.pinkPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              _buildCalendarCard(context, project),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),

      // Bottom Navigation Bar
      bottomNavigationBar: const WedifyBottomNavigationBar(currentIndex: 0),
    );
  }

  // 2. Main Action Banner
  Widget _buildMainActionBanner(BuildContext context, WeddingProject project) {
    final isStarted = project.isInitialized;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.slate900,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.slate900),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.stars_rounded,
                          color: Colors.white,
                          size: 14,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isStarted ? "PROJECT ACTIVE" : "NEW PROJECT",
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isStarted) ...[
                    const SizedBox(width: 8),
                    // Minimalist B&W Payment Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: project.isPaid ? Colors.black : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: project.isPaid ? Colors.black : Colors.black,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            project.isPaid
                                ? Icons.check_circle_rounded
                                : Icons.pending_outlined,
                            size: 12,
                            color: project.isPaid ? Colors.white : Colors.black,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            project.isPaid
                                ? "Payment: Completed"
                                : "Payment: Pending",
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: project.isPaid
                                  ? Colors.white
                                  : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              if (isStarted)
                GestureDetector(
                  onTap: () => _showStartProjectModal(context, project),
                  child: const Icon(
                    Icons.edit_calendar_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isStarted ? "Wedding Scheduled!" : "Start a Wedding Project",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isStarted
                ? "Date: ${DateFormat('MMM dd, yyyy').format(project.weddingDate!)} at ${project.weddingTime}"
                : "Set event date & time to unlock venue, layout planner & catering setup.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.3,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.pinkPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              onPressed: () => _showStartProjectModal(context, project),
              icon: Icon(
                isStarted
                    ? Icons.update_rounded
                    : Icons.add_circle_outline_rounded,
                size: 20,
              ),
              label: Text(
                isStarted ? "Change Date & Time" : "Plan a Wedding Now",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          if (isStarted) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white70, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () => _showCancelWeddingDialog(),
                icon: const Icon(
                  Icons.cancel_outlined,
                  size: 18,
                  color: Colors.white,
                ),
                label: const Text(
                  "Cancel Wedding Project",
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBookedVenueCard(BuildContext context, WeddingProject project) {
    final eventDate = project.weddingDate == null
        ? 'Event date to be confirmed'
        : DateFormat('d MMMM y').format(project.weddingDate!);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: const BoxDecoration(
              color: AppColors.blush,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.location_city_rounded, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'BOOKED VENUE',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  project.selectedVenueName!,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$eventDate • ${project.weddingTime ?? 'Time TBD'}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                if (project.selectedVenueAddress?.isNotEmpty == true) ...[
                  const SizedBox(height: 2),
                  Text(
                    project.selectedVenueAddress!,
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentIncompleteBanner(
    BuildContext context,
    WeddingProject project,
  ) {
    final currency = NumberFormat.currency(locale: 'en_MY', symbol: 'RM ');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.pinkLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.blush),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'PAYMENT INCOMPLETE',
            style: TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'You updated your booking. Please complete the remaining balance payment to confirm your changes.',
            style: TextStyle(color: AppColors.charcoal, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            'Balance due: ${currency.format(project.balanceDue)}',
            style: const TextStyle(
              color: AppColors.navy,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CheckoutScreen()),
            ),
            child: const Text('Pay Balance with Stripe'),
          ),
        ],
      ),
    );
  }

  // 3. Progress Card
  Widget _buildProgressCard(BuildContext context, WeddingProject project) {
    final percentInt = (project.progressPercentage * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
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
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Planning Progress",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "4 Core Setup Tasks",
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: project.isFullyCompleted
                      ? const Color(0xFFE3F0E9)
                      : AppColors.pinkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$percentInt% Complete",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: project.isFullyCompleted
                        ? AppColors.sage
                        : AppColors.pinkPrimary,
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
              minHeight: 10,
              backgroundColor: AppColors.slate100,
              color: AppColors.pinkPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Tasks badges status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildTaskStepBadge("Venue", project.isVenueCompleted),
              _buildTaskStepBadge("Planner", project.isPlannerCompleted),
              _buildTaskStepBadge("Invitations", project.isInvitationCompleted),
              _buildTaskStepBadge("Catering", project.isCateringCompleted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStepBadge(String title, bool isDone) {
    return Column(
      children: [
        Icon(
          isDone
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          size: 18,
          color: isDone ? AppColors.pinkPrimary : AppColors.slate400,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: isDone ? FontWeight.w700 : FontWeight.w500,
            color: isDone ? AppColors.slate900 : AppColors.slate400,
          ),
        ),
      ],
    );
  }

  // 4. 4 Features Grid (Venue, 2D Planner, Invitations, Catering)
  Widget _buildFourFeaturesGrid(BuildContext context, WeddingProject project) {
    final features = [
      _FeatureConfig(
        "Venue Finder",
        Icons.apartment_rounded,
        const VenueFinderScreen(),
        project.isVenueCompleted,
      ),
      _FeatureConfig(
        "2D Planner",
        Icons.architecture_rounded,
        const LayoutPlannerScreen(),
        project.isPlannerCompleted,
      ),
      _FeatureConfig(
        "Invitations",
        Icons.mark_email_unread_rounded,
        const InvitationGalleryScreen(),
        project.isInvitationCompleted,
      ),
      _FeatureConfig(
        "F&B Catering",
        Icons.cake_rounded,
        const CateringSelectorScreen(),
        project.isCateringCompleted,
      ),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: features
          .map(
            (f) => _buildFeatureTile(
              context,
              title: f.title,
              icon: f.icon,
              isCompleted: f.isCompleted,
              isUnlocked: project.isInitialized,
              onTap: () =>
                  _handleFeatureClick(context, project, f.screen, f.title),
            ),
          )
          .toList(),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required String title,
    required IconData icon,
    required bool isCompleted,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    final cardWidth = (MediaQuery.of(context).size.width - 40 - 36) / 4;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: cardWidth,
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  height: 64,
                  width: cardWidth,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppColors.pinkLight
                        : (isUnlocked
                              ? AppColors.slate100.withValues(alpha: 0.8)
                              : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.pinkBorder
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isUnlocked
                          ? (isCompleted
                                ? AppColors.pinkPrimary
                                : AppColors.slate800)
                          : AppColors.slate400,
                      size: 24,
                    ),
                  ),
                ),
                if (!isUnlocked)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: AppColors.slate600,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.lock_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                if (isCompleted)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.pinkPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isUnlocked ? AppColors.slate800 : AppColors.slate400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 5. Checkout Banner at 100% completion
  Widget _buildCheckoutBanner(BuildContext context, WeddingProject project) {
    final isPaid = project.isPaid;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.navy,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.navy),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isPaid ? AppColors.sage : AppColors.pinkPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              isPaid ? Icons.verified_rounded : Icons.shopping_bag_rounded,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPaid ? "Payment Completed" : "All Setup Complete! (100%)",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isPaid
                      ? "Your booking is locked in and confirmed."
                      : "Ready to checkout & book services.",
                  style: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinkPrimary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );
            },
            child: Text(
              isPaid ? "View Receipt" : "Checkout",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // 6. TableCalendar Widget Card
  Widget _buildCalendarCard(BuildContext context, WeddingProject project) {
    final bookedDate = project.weddingDate;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TableCalendar(
        firstDay: DateTime.now().subtract(const Duration(days: 365)),
        lastDay: DateTime.now().add(const Duration(days: 1095)),
        focusedDay: _focusedDay,
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {
          CalendarFormat.month: 'Month',
        },
        sixWeekMonthsEnforced: false,
        rowHeight: 46,
        daysOfWeekHeight: 28,
        selectedDayPredicate: (day) {
          if (bookedDate != null && isSameDay(bookedDate, day)) {
            return true;
          }
          return isSameDay(_selectedCalendarDay, day);
        },
        onDaySelected: (selectedDay, focusedDay) {
          setState(() {
            _selectedCalendarDay = selectedDay;
            _focusedDay = focusedDay;
          });
        },
        calendarStyle: CalendarStyle(
          selectedDecoration: const BoxDecoration(
            color: AppColors.pinkPrimary,
            shape: BoxShape.circle,
          ),
          todayDecoration: BoxDecoration(
            color: AppColors.pinkLight,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.pinkPrimary),
          ),
          todayTextStyle: const TextStyle(
            color: AppColors.pinkPrimary,
            fontWeight: FontWeight.bold,
          ),
          markerDecoration: const BoxDecoration(
            color: AppColors.pinkPrimary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w800,
            color: AppColors.slate900,
          ),
          leftChevronIcon: Icon(
            Icons.chevron_left_rounded,
            color: AppColors.slate700,
          ),
          rightChevronIcon: Icon(
            Icons.chevron_right_rounded,
            color: AppColors.slate700,
          ),
        ),
      ),
    );
  }
}

class _FeatureConfig {
  final String title;
  final IconData icon;
  final Widget screen;
  final bool isCompleted;

  _FeatureConfig(this.title, this.icon, this.screen, this.isCompleted);
}

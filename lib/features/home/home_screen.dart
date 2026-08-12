import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../core/theme/app_colors.dart';
import '../../models/wedding_project_model.dart';
import '../../services/wedding_project_provider.dart';
import '../auth/auth_screen.dart';
import '../venue/venue_finder_screen.dart';
import '../planner/layout_planner_screen.dart';
import '../invitation/invitation_gallery_screen.dart';
import '../catering/catering_selector_screen.dart';
import '../checkout/checkout_screen.dart';
import '../auth/user_profile_screen.dart';
import '../../services/auth_session_service.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedLocation = "Kuala Lumpur, MY";

  final List<String> _locations = [
    "Kuala Lumpur, MY",
    "California, US",
    "Penang, MY",
    "Johor Bahru, MY",
    "Singapore, SG",
  ];

  // Calendar State
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedCalendarDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate900),
        ),
        content: const Text("Are you sure you want to log out of Wedify?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinkPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  // Dialog to prompt user to select date and time
  Future<void> _showStartProjectModal(BuildContext context, WeddingProject project) async {
    DateTime selectedDate = project.weddingDate ?? DateTime.now().add(const Duration(days: 90));
    TimeOfDay selectedTime = const TimeOfDay(hour: 11, minute: 0);

    final isConfirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.pinkLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.favorite_rounded, color: AppColors.pinkPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "Wedding Schedule",
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: AppColors.slate900),
                  ),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Please select your planned Wedding Date and Time to initialize feature access.",
                    style: TextStyle(fontSize: 13, color: AppColors.slate600, height: 1.4),
                  ),
                  const SizedBox(height: 20),

                  // Date Picker Card
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 1095)),
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
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              datePickerTheme: DatePickerThemeData(
                                backgroundColor: Colors.white,
                                dayForegroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return Colors.white;
                                  }
                                  return AppColors.slate900;
                                }),
                                dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
                                  if (states.contains(WidgetState.selected)) {
                                    return AppColors.pinkPrimary;
                                  }
                                  return Colors.transparent;
                                }),
                                confirmButtonStyle: TextButton.styleFrom(
                                  foregroundColor: AppColors.pinkPrimary,
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              const Icon(Icons.calendar_today_rounded, color: AppColors.pinkPrimary, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Wedding Date", style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                                  Text(
                                    DateFormat('MMM dd, yyyy').format(selectedDate),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate400),
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
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                                  textStyle: const TextStyle(fontWeight: FontWeight.bold),
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
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                              const Icon(Icons.access_time_rounded, color: AppColors.pinkPrimary, size: 20),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text("Event Time", style: TextStyle(fontSize: 11, color: AppColors.slate500)),
                                  Text(
                                    selectedTime.format(context),
                                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.slate400),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  child: const Text("Cancel", style: TextStyle(color: AppColors.slate600)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  onPressed: () => Navigator.of(ctx).pop(true),
                  child: const Text("Start Project", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );

    if (isConfirmed == true && context.mounted) {
      final formattedTime = selectedTime.format(context);
      ref.read(weddingProjectProvider.notifier).setDateTime(selectedDate, formattedTime);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Wedding Project started for ${DateFormat('MMM dd, yyyy').format(selectedDate)} at $formattedTime!"),
          backgroundColor: AppColors.pinkPrimary,
        ),
      );
    }
  }

  void _handleFeatureClick(BuildContext context, WeddingProject project, Widget screen, String featureTitle) async {
    if (!project.isInitialized) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.lock_clock_rounded, color: AppColors.pinkPrimary),
              SizedBox(width: 10),
              Text("Feature Locked", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ],
          ),
          content: Text(
            "Please start your Wedding Project and set a Date & Time first before accessing $featureTitle.",
            style: const TextStyle(color: AppColors.slate700, fontSize: 13, height: 1.4),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.pinkPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: () {
                Navigator.of(ctx).pop();
                _showStartProjectModal(context, project);
              },
              child: const Text("Set Date & Time", style: TextStyle(color: Colors.white)),
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

    // Auto-update step completion status after navigating back
    if (featureTitle == "Venue Finder") {
      ref.read(weddingProjectProvider.notifier).updateVenue(
        venueName: result ?? "Selected Ballroom Venue",
        fee: 4500.0,
      );
    } else if (featureTitle == "2D Planner") {
      ref.read(weddingProjectProvider.notifier).updatePlannerLayout(
        layoutSummary: "Custom 10-Table Layout",
        fee: 800.0,
      );
    } else if (featureTitle == "Invitations") {
      ref.read(weddingProjectProvider.notifier).updateInvitation(
        invitationName: "Luxury Gold Card",
        fee: 650.0,
      );
    } else if (featureTitle == "F&B Catering") {
      ref.read(weddingProjectProvider.notifier).updateCatering(
        cateringPackage: "Premium Buffet Package",
        fee: 5500.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final project = ref.watch(weddingProjectProvider);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row: Grid Icon | Location Selector | Notification Bell & Logout
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.grid_view_rounded, color: AppColors.slate900, size: 20),
                      onPressed: () {},
                    ),
                  ),

                  // Location Selector Pill
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.slate100.withValues(alpha: 0.7),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: PopupMenuButton<String>(
                      initialValue: _selectedLocation,
                      onSelected: (loc) => setState(() => _selectedLocation = loc),
                      offset: const Offset(0, 40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      itemBuilder: (context) => _locations
                          .map((loc) => PopupMenuItem(
                                value: loc,
                                child: Text(loc, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              ))
                          .toList(),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_outlined, color: AppColors.pinkPrimary, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            _selectedLocation,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.slate600, size: 18),
                        ],
                      ),
                    ),
                  ),

                  // Bell & Logout Buttons
                  Row(
                    children: [
                      Stack(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: AppColors.slate100,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: IconButton(
                              icon: const Icon(Icons.notifications_none_rounded, color: AppColors.slate900, size: 22),
                              onPressed: () {},
                            ),
                          ),
                          Positioned(
                            right: 12,
                            top: 12,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.pinkPrimary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.slate100,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: IconButton(
                          tooltip: 'Logout',
                          icon: const Icon(Icons.logout_rounded, color: AppColors.pinkPrimary, size: 20),
                          onPressed: () => _handleLogout(context),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // 2. Hero Action: Prominent "Start a Wedding Project" Button
              _buildMainActionBanner(context, project),
              const SizedBox(height: 24),

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
      bottomNavigationBar: Container(
        height: 72,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(index: 0, icon: Icons.home_outlined, activeIcon: Icons.home_rounded, showDot: true),
            _buildNavItem(index: 1, icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded),
            _buildNavItem(index: 2, icon: Icons.chat_bubble_outline_rounded, activeIcon: Icons.chat_bubble_rounded),
            _buildNavItem(index: 3, icon: Icons.person_outline_rounded, activeIcon: Icons.person_rounded),
          ],
        ),
      ),
    );
  }

  // 2. Main Action Banner
  Widget _buildMainActionBanner(BuildContext context, WeddingProject project) {
    final isStarted = project.isInitialized;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF5E8E), Color(0xFFFF8FA3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFF5E8E).withValues(alpha: 0.35),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.stars_rounded, color: Colors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      isStarted ? "PROJECT ACTIVE" : "NEW PROJECT",
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ],
                ),
              ),
              if (isStarted)
                GestureDetector(
                  onTap: () => _showStartProjectModal(context, project),
                  child: const Icon(Icons.edit_calendar_rounded, color: Colors.white, size: 20),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            isStarted ? "Wedding Scheduled!" : "Start a Wedding Project",
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, height: 1.2),
          ),
          const SizedBox(height: 6),
          Text(
            isStarted
                ? "Date: ${DateFormat('MMM dd, yyyy').format(project.weddingDate!)} at ${project.weddingTime}"
                : "Set event date & time to unlock venue, layout planner & catering setup.",
            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.9), height: 1.3),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.pinkPrimary,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 0,
              ),
              onPressed: () => _showStartProjectModal(context, project),
              icon: Icon(isStarted ? Icons.update_rounded : Icons.add_circle_outline_rounded, size: 20),
              label: Text(
                isStarted ? "Change Date & Time" : "Plan a Wedding Now",
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
              ),
            ),
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
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate900),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "4 Core Setup Tasks",
                    style: TextStyle(fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: project.isFullyCompleted ? const Color(0xFFE8F5E9) : AppColors.pinkLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  "$percentInt% Complete",
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: project.isFullyCompleted ? const Color(0xFF2E7D32) : AppColors.pinkPrimary,
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
          isDone ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
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
      _FeatureConfig("Venue Finder", Icons.apartment_rounded, const VenueFinderScreen(), project.isVenueCompleted),
      _FeatureConfig("2D Planner", Icons.architecture_rounded, const LayoutPlannerScreen(), project.isPlannerCompleted),
      _FeatureConfig("Invitations", Icons.mark_email_unread_rounded, const InvitationGalleryScreen(), project.isInvitationCompleted),
      _FeatureConfig("F&B Catering", Icons.cake_rounded, const CateringSelectorScreen(), project.isCateringCompleted),
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
              onTap: () => _handleFeatureClick(context, project, f.screen, f.title),
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
                        : (isUnlocked ? AppColors.slate100.withValues(alpha: 0.8) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isCompleted ? AppColors.pinkBorder : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      icon,
                      color: isUnlocked ? (isCompleted ? AppColors.pinkPrimary : AppColors.slate800) : AppColors.slate400,
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
                      child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
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
                      child: const Icon(Icons.check_rounded, size: 10, color: Colors.white),
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
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.pinkPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.shopping_bag_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "All Setup Complete! (100%)",
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white),
                ),
                SizedBox(height: 2),
                Text(
                  "Ready to checkout & book services.",
                  style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                ),
              ],
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinkPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const CheckoutScreen()),
              );
            },
            child: const Text("Checkout", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        calendarFormat: _calendarFormat,
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
        onFormatChanged: (format) {
          setState(() => _calendarFormat = format);
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
          todayTextStyle: const TextStyle(color: AppColors.pinkPrimary, fontWeight: FontWeight.bold),
          markerDecoration: const BoxDecoration(
            color: AppColors.pinkPrimary,
            shape: BoxShape.circle,
          ),
        ),
        headerStyle: const HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          titleTextStyle: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.slate900),
          leftChevronIcon: Icon(Icons.chevron_left_rounded, color: AppColors.slate700),
          rightChevronIcon: Icon(Icons.chevron_right_rounded, color: AppColors.slate700),
        ),
      ),
    );
  }

  // Navigation Item
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    bool showDot = false,
  }) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () async {
        setState(() => _currentNavIndex = index);
        if (index == 3) {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const UserProfileScreen()),
          );
          if (mounted) {
            setState(() => _currentNavIndex = 0);
          }
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? activeIcon : icon,
            color: isSelected ? AppColors.pinkPrimary : AppColors.slate400,
            size: 26,
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

class _FeatureConfig {
  final String title;
  final IconData icon;
  final Widget screen;
  final bool isCompleted;

  _FeatureConfig(this.title, this.icon, this.screen, this.isCompleted);
}

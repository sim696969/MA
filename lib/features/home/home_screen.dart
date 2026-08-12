import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../venue/venue_finder_screen.dart';
import '../planner/layout_planner_screen.dart';
import '../invitation/invitation_gallery_screen.dart';
import '../catering/catering_selector_screen.dart';
import 'event_details_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentNavIndex = 0;
  String _selectedLocation = "California, US";

  final List<String> _locations = [
    "California, US",
    "Kuala Lumpur, MY",
    "Penang, MY",
    "Johor Bahru, MY",
    "Singapore, SG",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Top Header Row: Grid Icon | Location Selector | Notification Bell
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Grid Menu Button
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

                  // Location Dropdown Selector Pill
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

                  // Notification Bell with Badge Dot
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
                ],
              ),
              const SizedBox(height: 32),

              // 2. Hero Headline
              Center(
                child: RichText(
                  textAlign: TextAlign.center,
                  text: const TextSpan(
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                      height: 1.3,
                      fontFamily: 'Plus Jakarta Sans',
                    ),
                    children: [
                      TextSpan(text: "Create Your Own Version\nOf Perfect "),
                      TextSpan(
                        text: "Wedding",
                        style: TextStyle(
                          color: AppColors.pinkPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // 3. 8 Features Buttons Grid (4x2 layout from image)
              _buildEightFeaturesGrid(context),
              const SizedBox(height: 36),

              // 4. Recent Events Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Recent Events",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  GestureDetector(
                    onTap: () {},
                    child: const Text(
                      "View All",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 5. Recent Event Cards
              _buildEventCard(
                context,
                title: "Caroline & Ethan Wedding",
                date: "05 Mar, 2024",
                description: "Wedding party in the middle of the Minnesota",
                imagePath: "https://images.unsplash.com/photo-1519741497674-611481863552?w=500&auto=format&fit=crop&q=80",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventDetailsScreen(
                        title: "Caroline & Ethan Wedding",
                        date: "05 Mar, 2024",
                        location: "Grandview",
                        guests: "250-300 Guests",
                        price: "\$7500",
                        imagePath: "https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop&q=80",
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 16),
              _buildEventCard(
                context,
                title: "Paul & Jesi Wedding",
                date: "24 Feb, 2024",
                description: "Wedding ceremony at kingston palace",
                imagePath: "https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=500&auto=format&fit=crop&q=80",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EventDetailsScreen(
                        title: "Paul & Jesi Wedding",
                        date: "24 Feb, 2024",
                        location: "Kingston Palace",
                        guests: "180-220 Guests",
                        price: "\$6200",
                        imagePath: "https://images.unsplash.com/photo-1583939003579-730e3918a45a?w=800&auto=format&fit=crop&q=80",
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
      // 6. Bottom Navigation Bar matching mockup design
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
            // Home Icon with Pink Dot Below (Active)
            _buildNavItem(
              index: 0,
              icon: Icons.home_outlined,
              activeIcon: Icons.home_rounded,
              showDot: true,
            ),
            // Plus Icon
            _buildNavItem(
              index: 1,
              icon: Icons.add_circle_outline_rounded,
              activeIcon: Icons.add_circle_rounded,
            ),
            // Chat Icon
            _buildNavItem(
              index: 2,
              icon: Icons.chat_bubble_outline_rounded,
              activeIcon: Icons.chat_bubble_rounded,
            ),
            // Profile Icon
            _buildNavItem(
              index: 3,
              icon: Icons.person_outline_rounded,
              activeIcon: Icons.person_rounded,
            ),
          ],
        ),
      ),
    );
  }

  // 8 Features Buttons (2 rows x 4 items)
  Widget _buildEightFeaturesGrid(BuildContext context) {
    final row1Items = [
      _FeatureButtonData("Venue Finder", Icons.apartment_rounded, const VenueFinderScreen(), false),
      _FeatureButtonData("2D Planner", Icons.architecture_rounded, const LayoutPlannerScreen(), false),
      _FeatureButtonData("Invitations", Icons.mark_email_unread_rounded, const InvitationGalleryScreen(), false),
      _FeatureButtonData("F&B Catering", Icons.cake_rounded, const CateringSelectorScreen(), false),
    ];

    final row2Items = [
      _FeatureButtonData("Make up", Icons.brush_rounded, null, true),
      _FeatureButtonData("Music", Icons.music_note_rounded, null, true),
      _FeatureButtonData("Photo", Icons.camera_alt_rounded, null, true),
      _FeatureButtonData("Food", Icons.flatware_rounded, const CateringSelectorScreen(), true),
    ];

    return Column(
      children: [
        // Row 1 (Top 4 buttons - light slate style)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row1Items.map((item) => _buildFeatureItemTile(context, item)).toList(),
        ),
        const SizedBox(height: 16),
        // Row 2 (Bottom 4 buttons - pink tinted style matching mockup)
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: row2Items.map((item) => _buildFeatureItemTile(context, item)).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureItemTile(BuildContext context, _FeatureButtonData item) {
    return GestureDetector(
      onTap: () {
        if (item.targetScreen != null) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => item.targetScreen!),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Opening ${item.title}..."),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      },
      child: SizedBox(
        width: (MediaQuery.of(context).size.width - 40 - 36) / 4,
        child: Column(
          children: [
            Container(
              height: 64,
              decoration: BoxDecoration(
                color: item.isPinkAccent ? AppColors.pinkLight : AppColors.slate100.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: item.isPinkAccent ? AppColors.pinkBorder : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Center(
                child: Icon(
                  item.icon,
                  color: item.isPinkAccent ? AppColors.pinkPrimary : AppColors.slate800,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              item.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Recent Event Card Widget
  Widget _buildEventCard(
    BuildContext context, {
    required String title,
    required String date,
    required String description,
    required String imagePath,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.slate100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Row(
              children: [
                // Thumbnail Image
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    imagePath,
                    width: 90,
                    height: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 90,
                      height: 90,
                      color: AppColors.pinkLight,
                      child: const Icon(Icons.favorite_rounded, color: AppColors.pinkPrimary),
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                // Text details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.slate400,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.slate500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        "Read More",
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.pinkPrimary,
                        ),
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

  // Bottom Navigation Bar Item
  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData activeIcon,
    bool showDot = false,
  }) {
    final isSelected = _currentNavIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentNavIndex = index),
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

class _FeatureButtonData {
  final String title;
  final IconData icon;
  final Widget? targetScreen;
  final bool isPinkAccent;

  _FeatureButtonData(this.title, this.icon, this.targetScreen, this.isPinkAccent);
}

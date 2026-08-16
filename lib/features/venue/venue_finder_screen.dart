import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../services/wedding_project_provider.dart';
import '../../widgets/top_right_toast.dart';
import 'virtual_map_explorer_screen.dart';

class VenueFinderScreen extends ConsumerStatefulWidget {
  const VenueFinderScreen({super.key});

  @override
  ConsumerState<VenueFinderScreen> createState() => _VenueFinderScreenState();
}

class _VenueFinderScreenState extends ConsumerState<VenueFinderScreen> {
  String _selectedCategory = "All";
  String _searchQuery = "";

  // Filter criteria states
  String _filterPriceRange = "All";
  double _filterMinRating = 0.0;
  final List<String> _filterSelectedFacilities = [];

  final List<VenueCategory> _categories = [
    VenueCategory("All", Icons.apps_rounded),
    VenueCategory("Hotel", Icons.apartment_rounded),
    VenueCategory("Church", Icons.church_rounded),
    VenueCategory("Cafe", Icons.local_cafe_rounded),
    VenueCategory("Farm", Icons.agriculture_rounded),
    VenueCategory("Beach", Icons.beach_access_rounded),
  ];

  final List<VenueItem> _venues = [
    VenueItem(
      id: "1",
      name: "Blue hill at stone barns",
      location: "Tarrytown, New York",
      price: "\$9,900",
      rawPrice: 9900,
      priceUnit: "/night",
      rating: 4.8,
      reviewCount: 25,
      category: "Beach",
      imageUrl:
          "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80",
      coordinates: const LatLng(41.0964, -73.8340),
      facilities: [
        "Free wifi",
        "Parking",
        "Fitness (c)",
        "Hot tub",
        "Party hall",
      ],
    ),
    VenueItem(
      id: "2",
      name: "Grand Hyatt Glasshouse",
      location: "Kuala Lumpur, Malaysia",
      price: "\$8,500",
      rawPrice: 8500,
      priceUnit: "/event",
      rating: 4.9,
      reviewCount: 42,
      category: "Hotel",
      imageUrl:
          "https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=800&q=80",
      coordinates: const LatLng(3.1538, 101.7123),
      facilities: [
        "Free wifi",
        "Parking",
        "Party hall",
        "Catering",
        "VIP Lounge",
      ],
    ),
    VenueItem(
      id: "3",
      name: "St. Augustine Chapel",
      location: "Penang, Malaysia",
      price: "\$4,200",
      rawPrice: 4200,
      priceUnit: "/day",
      rating: 4.7,
      reviewCount: 18,
      category: "Church",
      imageUrl:
          "https://images.unsplash.com/photo-1544077960-604201fe74bc?auto=format&fit=crop&w=800&q=80",
      coordinates: const LatLng(5.4164, 100.3327),
      facilities: ["Organ Music", "Parking", "Garden Lawn", "Bridal Suite"],
    ),
    VenueItem(
      id: "4",
      name: "Botanical Farmhouse Estate",
      location: "Cameron Highlands, Malaysia",
      price: "\$6,800",
      rawPrice: 6800,
      priceUnit: "/night",
      rating: 4.6,
      reviewCount: 30,
      category: "Farm",
      imageUrl:
          "https://images.unsplash.com/photo-1464366400600-7168b8af9bc3?auto=format&fit=crop&w=800&q=80",
      coordinates: const LatLng(4.4716, 101.3776),
      facilities: ["Organic Catering", "Free wifi", "Firepit", "Party hall"],
    ),
    VenueItem(
      id: 'penang_eo_hotel',
      name: 'Eastern & Oriental Hotel (E&O)',
      location: 'George Town, Penang',
      description: 'Iconic heritage luxury hotel by the sea in George Town.',
      capacity: 'Up to 450 guests',
      price: 'RM 18,000',
      rawPrice: 18000,
      priceUnit: '/ event',
      rating: 4.9,
      reviewCount: 210,
      category: 'Hotel',
      imageUrl: 'https://images.unsplash.com/photo-1564501049412-61c2a3083791?auto=format&fit=crop&w=800&q=80',
      coordinates: const LatLng(5.4232, 100.3359),
      facilities: ['Ballroom', 'Sea view', 'Catering', 'Bridal Suite'],
    ),
    VenueItem(
      id: 'penang_rasa_sayang',
      name: 'Shangri-La Rasa Sayang, Penang',
      location: 'Batu Ferringhi, Penang',
      description: 'Luxury beachfront resort in Batu Ferringhi with garden & beach venues.',
      capacity: 'Up to 600 guests',
      price: 'RM 22,000',
      rawPrice: 22000,
      priceUnit: '/ event',
      rating: 4.8,
      reviewCount: 185,
      category: 'Beach',
      imageUrl: 'https://images.unsplash.com/photo-1544124499-58912cbddaad?auto=format&fit=crop&w=800&q=80',
      coordinates: const LatLng(5.4782, 100.2541),
      facilities: ['Beachfront', 'Garden', 'Catering', 'Parking'],
    ),
    VenueItem(
      id: 'penang_suffolk_house',
      name: 'The Suffolk House',
      location: 'Air Itam, Penang',
      description: 'Historic Anglo-Indian mansion, perfect for intimate garden weddings.',
      capacity: 'Up to 180 guests',
      price: 'RM 12,000',
      rawPrice: 12000,
      priceUnit: '/ event',
      rating: 4.8,
      reviewCount: 120,
      category: 'Hotel',
      imageUrl: 'https://images.unsplash.com/photo-1507504031003-b417219a0fde?auto=format&fit=crop&w=800&q=80',
      coordinates: const LatLng(5.4089, 100.3013),
      facilities: ['Garden', 'Heritage venue', 'Catering', 'Parking'],
    ),
    VenueItem(
      id: 'penang_blue_mansion',
      name: 'Cheong Fatt Tze (The Blue Mansion)',
      location: 'George Town, Penang',
      description: 'World-renowned heritage courtyard mansion in George Town.',
      capacity: 'Up to 120 guests',
      price: 'RM 15,000',
      rawPrice: 15000,
      priceUnit: '/ event',
      rating: 4.9,
      reviewCount: 240,
      category: 'Hotel',
      imageUrl: 'https://images.unsplash.com/photo-1566073771259-6a8506099945?auto=format&fit=crop&w=800&q=80',
      coordinates: const LatLng(5.4214, 100.3348),
      facilities: ['Courtyard', 'Heritage venue', 'Photography', 'Catering'],
    ),
    VenueItem(
      id: 'penang_hotel_jen',
      name: 'Hotel Jen Penang by Shangri-La',
      location: 'George Town, Penang',
      description: 'Modern city-center hotel ballroom venue near Komtar.',
      capacity: 'Up to 500 guests',
      price: 'RM 16,500',
      rawPrice: 16500,
      priceUnit: '/ event',
      rating: 4.7,
      reviewCount: 145,
      category: 'Hotel',
      imageUrl: 'https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80',
      coordinates: const LatLng(5.4140, 100.3312),
      facilities: ['Ballroom', 'City view', 'Catering', 'Parking'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Filter venues based on search text, category, price, rating, and facilities
    final filteredVenues = _venues.where((v) {
      final matchesCategory =
          _selectedCategory == "All" ||
          v.category.toLowerCase() == _selectedCategory.toLowerCase();
      final matchesSearch =
          _searchQuery.isEmpty ||
          v.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          v.location.toLowerCase().contains(_searchQuery.toLowerCase());

      // Price filter
      bool matchesPrice = true;
      if (_filterPriceRange == "Under \$5,000") {
        matchesPrice = v.rawPrice < 5000;
      } else if (_filterPriceRange == "\$5,000 - \$9,000") {
        matchesPrice = v.rawPrice >= 5000 && v.rawPrice <= 9000;
      } else if (_filterPriceRange == "Over \$9,000") {
        matchesPrice = v.rawPrice > 9000;
      }

      // Rating filter
      final matchesRating = v.rating >= _filterMinRating;

      // Facilities filter
      bool matchesFacilities = true;
      if (_filterSelectedFacilities.isNotEmpty) {
        matchesFacilities = _filterSelectedFacilities.every(
          (fac) => v.facilities.contains(fac),
        );
      }

      return matchesCategory &&
          matchesSearch &&
          matchesPrice &&
          matchesRating &&
          matchesFacilities;
    }).toList();

    final bookedProject = ref.watch(weddingProjectProvider);
    final bookedVenueId = bookedProject.selectedVenueId;
    final bookedVenueName = bookedProject.selectedVenueName;
    if ((bookedVenueId?.isNotEmpty ?? false) ||
        (bookedVenueName?.isNotEmpty ?? false)) {
      filteredVenues.sort((a, b) {
        final aIsBooked = a.id == bookedVenueId || a.name == bookedVenueName;
        final bIsBooked = b.id == bookedVenueId || b.name == bookedVenueName;
        if (aIsBooked && !bIsBooked) return -1;
        if (bIsBooked && !aIsBooked) return 1;
        return 0;
      });
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 1. Updated Top App Bar Header (Back Arrow Icon | Title | Top Right Map Icon Button)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              child: Row(
                children: [
                  // Back Arrow Navigation Button to return to dashboard
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 18,
                        color: AppColors.slate900,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Text(
                    "Venue Finder",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  const Spacer(),
                  // Top Right Map Icon Button: Opens dedicated Virtual Map Explorer Screen
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.map_outlined,
                        color: AppColors.slate900,
                        size: 22,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                VirtualMapExplorerScreen(venues: _venues),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),

            // 2. Search Box + Filter Icon Button (with simple filter modal trigger)
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.slate100.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        onChanged: (val) => setState(() => _searchQuery = val),
                        decoration: const InputDecoration(
                          hintText: "Find your venue",
                          hintStyle: TextStyle(
                            color: AppColors.slate400,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: AppColors.slate400,
                            size: 20,
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Filter Icon Button (Triggers interactive Filter Modal)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: const BoxDecoration(
                      color: AppColors.slate900,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(
                        Icons.tune_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                      onPressed: () => _openFilterModal(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // 3. Horizontal Venue Category Bar (Hotel, Church, Cafe, Farm, Beach)
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final cat = _categories[index];
                  final isSelected = _selectedCategory == cat.name;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6.0),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedCategory = cat.name),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.slate900
                                  : AppColors.slate100.withValues(alpha: 0.7),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              cat.icon,
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.slate600,
                              size: 22,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            cat.name,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? AppColors.slate900
                                  : AppColors.slate500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),

            // 4. Famous Venues Header Row
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Famous venues",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.slate900,
                    ),
                  ),
                  Text(
                    "${filteredVenues.length} found",
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.slate500,
                    ),
                  ),
                ],
              ),
            ),

            // 5. Famous Venues List View
            Expanded(
              child: filteredVenues.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Icon(
                            Icons.search_off_rounded,
                            size: 48,
                            color: AppColors.slate400,
                          ),
                          SizedBox(height: 12),
                          Text(
                            "No venues match your filter",
                            style: TextStyle(
                              color: AppColors.slate600,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 8,
                      ),
                      itemCount: filteredVenues.length,
                      itemBuilder: (context, index) {
                        return _buildFamousVenueCard(
                          context,
                          filteredVenues[index],
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // Famous Venue Card Widget
  Widget _buildFamousVenueCard(BuildContext context, VenueItem venue) {
    final project = ref.watch(weddingProjectProvider);
    final isActiveSelection = project.selectedVenueId == venue.id ||
        (project.selectedVenueId == null &&
            project.selectedVenueName == venue.name);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: GestureDetector(
        onTap: () => _openVenueBookingDetails(context, venue),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isActiveSelection ? AppColors.blush : AppColors.slate100,
              width: isActiveSelection ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with Favorite Toggle
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    child: Image.network(
                      venue.imageUrl,
                      width: double.infinity,
                      height: 200,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 200,
                        color: AppColors.slate100,
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 64,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 14,
                    left: 14,
                    child: isActiveSelection
                        ? Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.blush,
                            borderRadius: BorderRadius.all(Radius.circular(20)),
                          ),
                          child: const Text(
                            'BOOKED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        )
                        : const SizedBox.shrink(),
                  ),
                  Positioned(
                    top: 14,
                    right: 14,
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(color: Colors.black12, blurRadius: 8),
                        ],
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(
                          venue.isFavorite
                              ? Icons.favorite_rounded
                              : Icons.favorite_border_rounded,
                          color: venue.isFavorite
                              ? Colors.redAccent
                              : AppColors.slate800,
                          size: 18,
                        ),
                        onPressed: () {
                          setState(() {
                            venue.isFavorite = !venue.isFavorite;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              // Venue Information Footer
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            venue.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            venue.location,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
                        children: [
                          TextSpan(
                            text: venue.price,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: AppColors.slate900,
                            ),
                          ),
                          TextSpan(
                            text: venue.priceUnit,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Interactive Filter Bottom Sheet Modal
  void _openFilterModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Filter Venues",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.close_rounded,
                          color: AppColors.slate400,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 1. Price Filter Options
                  const Text(
                    "Price Range",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          "All",
                          "Under \$5,000",
                          "\$5,000 - \$9,000",
                          "Over \$9,000",
                        ].map((range) {
                          final isSelected = _filterPriceRange == range;
                          return ChoiceChip(
                            label: Text(range),
                            selected: isSelected,
                            selectedColor: AppColors.slate900,
                            backgroundColor: AppColors.slate100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.slate900,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(() => _filterPriceRange = range);
                              }
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 2. Minimum Rating Filter
                  const Text(
                    "Minimum Rating",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          {"label": "All", "val": 0.0},
                          {"label": "★ 4.5+", "val": 4.5},
                          {"label": "★ 4.8+", "val": 4.8},
                        ].map((item) {
                          final isSelected = _filterMinRating == item["val"];
                          return ChoiceChip(
                            label: Text(item["label"] as String),
                            selected: isSelected,
                            selectedColor: AppColors.slate900,
                            backgroundColor: AppColors.slate100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.slate900,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              if (selected) {
                                setModalState(
                                  () =>
                                      _filterMinRating = item["val"] as double,
                                );
                              }
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),

                  // 3. Facilities Filter
                  const Text(
                    "Facilities Required",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.slate900,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children:
                        [
                          "Free wifi",
                          "Parking",
                          "Party hall",
                          "Hot tub",
                          "Garden Lawn",
                        ].map((fac) {
                          final isSelected = _filterSelectedFacilities.contains(
                            fac,
                          );
                          return FilterChip(
                            label: Text(fac),
                            selected: isSelected,
                            selectedColor: AppColors.slate900,
                            backgroundColor: AppColors.slate100,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.slate900,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                            onSelected: (selected) {
                              setModalState(() {
                                if (selected) {
                                  _filterSelectedFacilities.add(fac);
                                } else {
                                  _filterSelectedFacilities.remove(fac);
                                }
                              });
                            },
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 28),

                  // Reset & Apply Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _filterPriceRange = "All";
                              _filterMinRating = 0.0;
                              _filterSelectedFacilities.clear();
                            });
                            Navigator.pop(context);
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: AppColors.slate200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Reset",
                            style: TextStyle(
                              color: AppColors.slate900,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {}); // Apply state change
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.slate900,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: const Text(
                            "Apply Filter",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Specific Venue Booking Details Modal (NO MAP & NO RECEPTANT)
  void _openVenueBookingDetails(BuildContext context, VenueItem venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          child: Column(
            children: [
              // 1. Top Image Header with Overlay Buttons (< back, ♡ favorite, ⤤ share)
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(32),
                    ),
                    child: Image.network(
                      venue.imageUrl,
                      width: double.infinity,
                      height: 280,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 280,
                        color: AppColors.slate100,
                        child: const Icon(
                          Icons.apartment_rounded,
                          size: 64,
                          color: AppColors.slate400,
                        ),
                      ),
                    ),
                  ),
                  // Back Button
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: const Icon(
                          Icons.arrow_back_ios_new_rounded,
                          size: 16,
                          color: AppColors.slate900,
                        ),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ),
                  // Favorite & Share Buttons
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.favorite_border_rounded,
                              size: 18,
                              color: AppColors.slate900,
                            ),
                            onPressed: () {},
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 40,
                          height: 40,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: IconButton(
                            icon: const Icon(
                              Icons.share_outlined,
                              size: 18,
                              color: AppColors.slate900,
                            ),
                            onPressed: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              // 2. Details Content Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name & Price Header Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  venue.name,
                                  style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  venue.location,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          RichText(
                            text: TextSpan(
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                              ),
                              children: [
                                TextSpan(
                                  text: venue.price,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.slate900,
                                  ),
                                ),
                                TextSpan(
                                  text: "\n${venue.priceUnit}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.slate500,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 3. Social Proof / Reviewers + Star Rating
                      Row(
                        children: [
                          SizedBox(
                            width: 60,
                            height: 28,
                            child: Stack(
                              children: const [
                                Positioned(
                                  left: 0,
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundImage: NetworkImage(
                                      "https://i.pravatar.cc/150?img=11",
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 14,
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundImage: NetworkImage(
                                      "https://i.pravatar.cc/150?img=12",
                                    ),
                                  ),
                                ),
                                Positioned(
                                  left: 28,
                                  child: CircleAvatar(
                                    radius: 13,
                                    backgroundColor: AppColors.slate900,
                                    child: Text(
                                      "25+",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            "People reviewed",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.slate500,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          Row(
                            children: [
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 18,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${venue.rating} /5",
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.slate900,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),

                      // 4. Most popular facilities Section
                      const Text(
                        "Most popular facilities",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.slate900,
                        ),
                      ),
                      const SizedBox(height: 14),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _buildFacilityTile("Free wifi", Icons.wifi_rounded),
                            _buildFacilityTile(
                              "Parking",
                              Icons.directions_car_rounded,
                            ),
                            _buildFacilityTile(
                              "Fitness (c)",
                              Icons.fitness_center_rounded,
                            ),
                            _buildFacilityTile(
                              "Hot tub",
                              Icons.hot_tub_rounded,
                            ),
                            _buildFacilityTile(
                              "Party hall",
                              Icons.roofing_rounded,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      // NOTE: MAP & RECEPTANT REMOVED AS SPECIFIED BY USER!
                    ],
                  ),
                ),
              ),

              // 5. Bottom Action Bar: "Book now" (Clean Black Pill Button)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: () async {
                      final fee = double.tryParse(
                            venue.price.replaceAll(RegExp(r'[^0-9.]'), ''),
                          ) ??
                          0.0;
                      try {
                        final paymentResult = await ref
                            .read(weddingProjectProvider.notifier)
                            .bookVenue(
                              venueName: venue.name,
                              venueId: venue.id,
                              venueAddress: venue.location,
                              fee: fee,
                            );
                        if (!context.mounted) return;
                        if (paymentResult.type ==
                            PaymentModificationType.refundDue) {
                          await showDialog<void>(
                            context: context,
                            builder: (dialogContext) => AlertDialog(
                              backgroundColor: Colors.white,
                              surfaceTintColor: Colors.transparent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: const BorderSide(color: Colors.black),
                              ),
                              title: const Text('Booking Updated - Refund Notice'),
                              content: Text(
                                'Your updated total is lower than your previously paid amount. Your payment status remains COMPLETE. Our team will contact you via email regarding your refund process for the price difference of RM ${paymentResult.amount.toStringAsFixed(2)}.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(dialogContext),
                                  child: const Text('OK'),
                                ),
                              ],
                            ),
                          );
                        } else if (paymentResult.type ==
                            PaymentModificationType.balanceDue) {
                          context.showTopRightWarning(
                            'Payment incomplete. RM ${paymentResult.amount.toStringAsFixed(2)} is due.',
                          );
                        } else {
                          context.showTopRightSuccess(
                            paymentResult.type == PaymentModificationType.unchanged
                                ? 'Booking details updated successfully.'
                                : 'Venue ${venue.name} successfully booked!',
                          );
                        }
                        Navigator.pop(context, {
                          'venueName': venue.name,
                          'fee': fee,
                        });
                      } catch (e) {
                        if (!context.mounted) return;
                        context.showTopRightError('Unable to book venue: $e');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.slate900,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                    ),
                    child: const Text(
                      "Book now",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // Facility Tile Widget
  Widget _buildFacilityTile(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(right: 10.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.slate100.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.slate200.withValues(alpha: 0.5)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.slate700),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.slate700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class VenueCategory {
  final String name;
  final IconData icon;

  VenueCategory(this.name, this.icon);
}

class VenueItem {
  final String id;
  final String name;
  final String location;
  final String description;
  final String capacity;
  final String price;
  final int rawPrice;
  final String priceUnit;
  final double rating;
  final int reviewCount;
  final String category;
  final String imageUrl;
  final LatLng coordinates;
  final List<String> facilities;
  bool isFavorite;

  VenueItem({
    required this.id,
    required this.name,
    required this.location,
    this.description = '',
    this.capacity = 'Capacity on request',
    required this.price,
    required this.rawPrice,
    required this.priceUnit,
    required this.rating,
    required this.reviewCount,
    required this.category,
    required this.imageUrl,
    required this.coordinates,
    required this.facilities,
    this.isFavorite = false,
  });
}

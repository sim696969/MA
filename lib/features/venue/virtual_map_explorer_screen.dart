import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/open_street_map_widget.dart';
import '../../widgets/top_right_toast.dart';
import 'venue_finder_screen.dart';

class VirtualMapExplorerScreen extends StatefulWidget {
  final List<VenueItem> venues;

  const VirtualMapExplorerScreen({
    super.key,
    required this.venues,
  });

  @override
  State<VirtualMapExplorerScreen> createState() => _VirtualMapExplorerScreenState();
}

class _VirtualMapExplorerScreenState extends State<VirtualMapExplorerScreen> {
  final TextEditingController _addressSearchController = TextEditingController();
  final MapController _mapController = MapController();
  String _addressQuery = "";
  VenueItem? _selectedVenue;
  LatLng? _customLocationPin;
  String _customLocationName = "";

  // Region locations map for quick search
  final Map<String, LatLng> _regionCoordinates = {
    "Penang": const LatLng(5.4164, 100.3327),
    "Kuala Lumpur": const LatLng(3.1538, 101.7123),
    "New York": const LatLng(41.0964, -73.8340),
    "Highlands": const LatLng(4.4716, 101.3776),
  };

  void _moveToRegion(String regionName, LatLng point) {
    _addressSearchController.text = regionName;
    setState(() {
      _addressQuery = regionName;
      _selectedVenue = null;
    });
    _mapController.move(point, 12.0);
  }

  Future<void> _locateMe() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw StateError('Location services are disabled.');
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw StateError('Location permission was not granted.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      _mapController.move(LatLng(position.latitude, position.longitude), 14.0);
    } catch (error) {
      if (mounted) context.showTopRightError('Unable to find your location: $error');
    }
  }

  void _showVenueDetailsSheet(VenueItem venue) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.warmCream,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.pinkBorder,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  venue.imageUrl,
                  height: 150,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 150,
                    color: AppColors.pinkLight,
                    child: const Icon(
                      Icons.location_city_rounded,
                      color: AppColors.navy,
                      size: 48,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                venue.name,
                style: const TextStyle(
                  color: AppColors.navy,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                venue.location,
                style: const TextStyle(color: AppColors.slate600),
              ),
              const SizedBox(height: 10),
              Text(
                venue.description,
                style: const TextStyle(color: AppColors.charcoal, height: 1.4),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const Icon(Icons.groups_outlined, color: AppColors.blush),
                  const SizedBox(width: 6),
                  Text(venue.capacity),
                  const Spacer(),
                  Text(
                    '${venue.price} ${venue.priceUnit}',
                    style: const TextStyle(
                      color: AppColors.navy,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.showTopRightSuccess('${venue.name} selected');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.blush,
                    foregroundColor: Colors.white,
                    shape: const StadiumBorder(),
                  ),
                  child: const Text('Select Venue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filter venues on OpenStreetMap based on search query
    final mapVenues = widget.venues.where((v) {
      if (_addressQuery.isEmpty) return true;
      return v.location.toLowerCase().contains(_addressQuery.toLowerCase()) ||
          v.name.toLowerCase().contains(_addressQuery.toLowerCase()) ||
          v.category.toLowerCase().contains(_addressQuery.toLowerCase());
    }).toList();

    final pinsData = mapVenues
        .map((v) => OsmPinData(
              id: v.id,
              title: v.name,
              location: v.location,
              price: v.price,
              rating: v.rating,
              point: v.coordinates,
              category: v.category,
            ))
        .toList();

    return Scaffold(
      backgroundColor: AppColors.warmCream,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. Real OpenStreetMap Engine (using flutter_map & OpenStreetMap tile servers)
            OpenStreetMapWidget(
              mapController: _mapController,
              pins: pinsData,
              initialCenter: const LatLng(5.4141, 100.3288),
              initialZoom: 12.5,
              selectedPin: _selectedVenue != null
                  ? OsmPinData(
                      id: _selectedVenue!.id,
                      title: _selectedVenue!.name,
                      location: _selectedVenue!.location,
                      price: _selectedVenue!.price,
                      rating: _selectedVenue!.rating,
                      point: _selectedVenue!.coordinates,
                      category: _selectedVenue!.category,
                    )
                  : null,
              onPinSelected: (pin) {
                final venue = mapVenues.firstWhere((v) => v.id == pin.id);
                setState(() {
                  _selectedVenue = venue;
                  _customLocationPin = null;
                });
                _mapController.move(pin.point, 13.5);
                _showVenueDetailsSheet(venue);
              },
              onLocationTapped: (point) {
                setState(() {
                  _selectedVenue = null;
                  _customLocationPin = point;
                  _customLocationName =
                      "OpenStreetMap Pin (${point.latitude.toStringAsFixed(4)}, ${point.longitude.toStringAsFixed(4)})";
                });
              },
            ),

            // 2. Top Navigation Bar & Search Input Textbox
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Row(
                children: [
                  // Back Arrow Navigation Button
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 10,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.slate900),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Top Middle Search Field for OpenStreetMap Address & Region
                  Expanded(
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: AppColors.slate200),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 12,
                            offset: Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _addressSearchController,
                        onChanged: (val) {
                          setState(() => _addressQuery = val);
                        },
                        onSubmitted: (val) {
                          if (_regionCoordinates.containsKey(val)) {
                            _mapController.move(_regionCoordinates[val]!, 12.0);
                          }
                        },
                        decoration: InputDecoration(
                          hintText: "Search OpenStreetMap address (e.g. Penang)...",
                          hintStyle: const TextStyle(fontSize: 12, color: AppColors.slate400),
                          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.slate900, size: 20),
                          suffixIcon: _addressSearchController.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.slate500),
                                  onPressed: () {
                                    _addressSearchController.clear();
                                    setState(() => _addressQuery = "");
                                  },
                                )
                              : null,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Positioned(
              right: 16,
              bottom: 124,
              child: Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                elevation: 3,
                child: IconButton(
                  tooltip: 'Locate me',
                  icon: const Icon(Icons.my_location_rounded, color: AppColors.blush),
                  onPressed: _locateMe,
                ),
              ),
            ),

            // 3. Quick Region Quick-Jump Chips (Penang, KL, New York, Highlands)
            Positioned(
              top: 76,
              left: 16,
              right: 16,
              child: SizedBox(
                height: 36,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _buildRegionChip("All Regions", "", const LatLng(3.1538, 101.7123)),
                    _buildRegionChip("Penang", "Penang", _regionCoordinates["Penang"]!),
                    _buildRegionChip("Kuala Lumpur", "Kuala Lumpur", _regionCoordinates["Kuala Lumpur"]!),
                    _buildRegionChip("New York", "New York", _regionCoordinates["New York"]!),
                    _buildRegionChip("Highlands", "Highlands", _regionCoordinates["Highlands"]!),
                  ],
                ),
              ),
            ),

            // 4. Selected Venue Details Preview Card (Bottom Sheet Floating Card)
            if (_selectedVenue != null)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.network(
                          _selectedVenue!.imageUrl,
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Container(
                            width: 80,
                            height: 80,
                            color: AppColors.slate100,
                            child: const Icon(Icons.apartment_rounded, color: AppColors.slate400),
                          ),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _selectedVenue!.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _selectedVenue!.location,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.slate500,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              "${_selectedVenue!.price} ${_selectedVenue!.priceUnit}",
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w800,
                                color: AppColors.slate900,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded, color: AppColors.slate400),
                        onPressed: () => setState(() => _selectedVenue = null),
                      ),
                    ],
                  ),
                ),
              ),

            // 5. Custom Tapped Pin Details Banner
            if (_customLocationPin != null && _selectedVenue == null)
              Positioned(
                bottom: 24,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.slate900,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: const [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 16,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.location_on_rounded, color: Colors.white, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              "OpenStreetMap Location Selected",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _customLocationName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text("Location saved for venue search!")),
                          );
                        },
                        child: const Text("Select", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionChip(String label, String queryValue, LatLng targetCoord) {
    final isSelected = _addressQuery.toLowerCase() == queryValue.toLowerCase();
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: () => _moveToRegion(queryValue, targetCoord),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.slate900 : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: isSelected ? AppColors.slate900 : AppColors.slate200),
            boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6)],
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.slate800,
            ),
          ),
        ),
      ),
    );
  }
}

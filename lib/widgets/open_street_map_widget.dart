import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../core/theme/app_colors.dart';

class OsmPinData {
  final String id;
  final String title;
  final String location;
  final String price;
  final double rating;
  final LatLng point;
  final String category;

  OsmPinData({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.point,
    required this.category,
  });
}

class OpenStreetMapWidget extends StatefulWidget {
  final List<OsmPinData> pins;
  final OsmPinData? selectedPin;
  final LatLng? initialCenter;
  final double initialZoom;
  final MapController? mapController;
  final Function(OsmPinData pin)? onPinSelected;
  final Function(LatLng position)? onLocationTapped;

  const OpenStreetMapWidget({
    super.key,
    required this.pins,
    this.selectedPin,
    this.initialCenter,
    this.initialZoom = 11.0,
    this.mapController,
    this.onPinSelected,
    this.onLocationTapped,
  });

  @override
  State<OpenStreetMapWidget> createState() => _OpenStreetMapWidgetState();
}

class _OpenStreetMapWidgetState extends State<OpenStreetMapWidget> {
  LatLng? _customPinPosition;

  @override
  Widget build(BuildContext context) {
    final defaultCenter = widget.initialCenter ??
        (widget.pins.isNotEmpty ? widget.pins.first.point : const LatLng(3.1390, 101.6869));

    return Stack(
      children: [
        // OpenStreetMap Tile Engine via flutter_map
        FlutterMap(
          mapController: widget.mapController,
          options: MapOptions(
            initialCenter: defaultCenter,
            initialZoom: widget.initialZoom,
            minZoom: 3.0,
            maxZoom: 18.0,
            onTap: (tapPosition, point) {
              setState(() {
                _customPinPosition = point;
              });
              if (widget.onLocationTapped != null) {
                widget.onLocationTapped!(point);
              }
            },
          ),
          children: [
            // Standard OpenStreetMap TileLayer
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.wedify.app',
            ),

            // Venue Markers Layer
            MarkerLayer(
              markers: [
                // Render Venue Pins
                ...widget.pins.map((pin) {
                  final isSelected = widget.selectedPin?.id == pin.id;
                  return Marker(
                    point: pin.point,
                    width: 140,
                    height: 70,
                    alignment: Alignment.topCenter,
                    child: GestureDetector(
                      onTap: () {
                        if (widget.onPinSelected != null) {
                          widget.onPinSelected!(pin);
                        }
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? AppColors.navy : AppColors.pinkBorder,
                                width: 1.5,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Text(
                              "${pin.title} • ${pin.price}",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.navy,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Icon(
                            Icons.location_on_rounded,
                            size: isSelected ? 34 : 26,
                            color: isSelected ? AppColors.navy : AppColors.blush,
                          ),
                        ],
                      ),
                    ),
                  );
                }),

                // User Custom Dropped Pin (if user taps anywhere on OpenStreetMap)
                if (_customPinPosition != null)
                  Marker(
                    point: _customPinPosition!,
                    width: 100,
                    height: 60,
                    alignment: Alignment.topCenter,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.navy,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            "Selected Pin",
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const Icon(
                          Icons.my_location_rounded,
                          size: 28,
                          color: AppColors.blush,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ],
        ),

        // Attribution Badge
        Positioned(
          bottom: 6,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              "© OpenStreetMap contributors",
              style: TextStyle(fontSize: 10, color: AppColors.slate600, fontWeight: FontWeight.w500),
            ),
          ),
        ),
      ],
    );
  }
}

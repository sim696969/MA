import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class MapPinData {
  final String id;
  final String title;
  final String location;
  final String price;
  final double rating;
  final Offset position; // normalized offset (0.0 to 1.0)
  final String category;

  MapPinData({
    required this.id,
    required this.title,
    required this.location,
    required this.price,
    required this.rating,
    required this.position,
    required this.category,
  });
}

class Virtual2DMapWidget extends StatefulWidget {
  final List<MapPinData> pins;
  final MapPinData? selectedPin;
  final Function(MapPinData pin)? onPinSelected;
  final Function(Offset position)? onLocationDropped;

  const Virtual2DMapWidget({
    super.key,
    required this.pins,
    this.selectedPin,
    this.onPinSelected,
    this.onLocationDropped,
  });

  @override
  State<Virtual2DMapWidget> createState() => _Virtual2DMapWidgetState();
}

class _Virtual2DMapWidgetState extends State<Virtual2DMapWidget> {
  Offset? _customPinPosition;
  String _customAddressText = "Tap map to select custom location";

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = constraints.maxHeight;

        return Stack(
          children: [
            // Interactive 2D Painter Grid & Map Base
            GestureDetector(
              onTapUp: (details) {
                final localPos = details.localPosition;
                final normalized = Offset(
                  (localPos.dx / width).clamp(0.0, 1.0),
                  (localPos.dy / height).clamp(0.0, 1.0),
                );

                setState(() {
                  _customPinPosition = normalized;
                  _customAddressText =
                      "Virtual Sector (${(normalized.dx * 100).toInt()}, ${(normalized.dy * 100).toInt()}) - Selected Venue Site";
                });

                if (widget.onLocationDropped != null) {
                  widget.onLocationDropped!(normalized);
                }
              },
              child: CustomPaint(
                size: Size(width, height),
                painter: Clean2DMapPainter(),
              ),
            ),

            // Render Venue Pins
            ...widget.pins.map((pin) {
              final isSelected = widget.selectedPin?.id == pin.id;
              final pinX = pin.position.dx * width;
              final pinY = pin.position.dy * height;

              return Positioned(
                left: pinX - 24,
                top: pinY - 48,
                child: GestureDetector(
                  onTap: () {
                    if (widget.onPinSelected != null) {
                      widget.onPinSelected!(pin);
                    }
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge tooltip overlay
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.slate900 : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? AppColors.slate900 : AppColors.slate300,
                            width: 1.5,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 8,
                              offset: Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Text(
                          "${pin.title} • ${pin.price}",
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isSelected ? Colors.white : AppColors.slate900,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      // Marker Icon
                      Icon(
                        Icons.location_on_rounded,
                        size: isSelected ? 36 : 28,
                        color: isSelected ? AppColors.slate900 : AppColors.slate700,
                      ),
                    ],
                  ),
                ),
              );
            }),

            // Render User Custom Selected Pin (if tapped somewhere on map)
            if (_customPinPosition != null)
              Positioned(
                left: _customPinPosition!.dx * width - 20,
                top: _customPinPosition!.dy * height - 40,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.slate900,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        "Your Pin",
                        style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const Icon(
                      Icons.my_location_rounded,
                      size: 32,
                      color: AppColors.slate900,
                    ),
                  ],
                ),
              ),

            // Top Instructions Overlay Badge
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.slate200),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 10,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.touch_app_rounded, color: AppColors.slate900, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _customAddressText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.slate800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

// Custom 2D Vector Map Painter (Monochrome Clean Black & White Style)
class Clean2DMapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFFF8FAFC);
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = const Color(0xFFE2E8F0)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const gridStep = 40.0;
    for (double x = 0; x < size.width; x += gridStep) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridStep) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Stylized Park / Garden Green Zones (Monochrome soft grey tone)
    final zonePaint = Paint()
      ..color = const Color(0xFFEDF2F7)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.1, size.height * 0.15, size.width * 0.35, size.height * 0.25),
        const Radius.circular(20),
      ),
      zonePaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(size.width * 0.55, size.height * 0.5, size.width * 0.35, size.height * 0.3),
        const Radius.circular(24),
      ),
      zonePaint,
    );

    // Stylized River / Shoreline (Monochrome subtle slate accent)
    final riverPaint = Paint()
      ..color = const Color(0xFFCBD5E1)
      ..strokeWidth = 24
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final riverPath = Path()
      ..moveTo(0, size.height * 0.4)
      ..cubicTo(size.width * 0.3, size.height * 0.35, size.width * 0.6, size.height * 0.6, size.width, size.height * 0.45);
    canvas.drawPath(riverPath, riverPaint);

    // Stylized Main Roads (Clean Dark Slate Roads)
    final roadPaint = Paint()
      ..color = const Color(0xFF94A3B8)
      ..strokeWidth = 8
      ..style = PaintingStyle.stroke;

    // Horizontal main road
    canvas.drawLine(Offset(0, size.height * 0.65), Offset(size.width, size.height * 0.65), roadPaint);
    // Vertical main road
    canvas.drawLine(Offset(size.width * 0.48, 0), Offset(size.width * 0.48, size.height), roadPaint);

    // Building Blocks
    final buildingPaint = Paint()..color = const Color(0xFFCBD5E1);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.15, size.height * 0.7, 45, 35), buildingPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.7, size.height * 0.2, 50, 40), buildingPaint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.3, size.height * 0.78, 60, 30), buildingPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

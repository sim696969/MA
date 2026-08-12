import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/wedify_button.dart';
import '../auth/auth_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  final List<OnboardingSlideData> _pages = [
    OnboardingSlideData(
      titlePrefix: "Plan Your ",
      titleHighlight: "Wedding",
      titleSuffix: "\nEvents Easily",
      description: "Now you dont have to search individually,\nAll in just one platform",
      imageType: OnboardingImageType.weddingCouple,
    ),
    OnboardingSlideData(
      titlePrefix: "Discover Perfect ",
      titleHighlight: "Venues",
      titleSuffix: "\n& 2D Planner",
      description: "Find magnificent venues and design your interactive 2D layout effortlessly.",
      imageType: OnboardingImageType.venuePlanner,
    ),
    OnboardingSlideData(
      titlePrefix: "Seamless ",
      titleHighlight: "Invitations",
      titleSuffix: "\n& Catering",
      description: "Send gorgeous digital invites and customize your dream F&B menu with ease.",
      imageType: OnboardingImageType.invitationsCatering,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            // Header Logo: Pink Dot + WEDIFY
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColors.pinkPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "W E D I F Y",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4.0,
                    color: AppColors.slate900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // PageView Carousel
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pages.length,
                onPageChanged: (index) => setState(() => _currentPage = index),
                itemBuilder: (context, index) {
                  final page = _pages[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Illustration Circle Container
                        _buildIllustrationCircle(page.imageType),
                        const SizedBox(height: 40),
                        // Rich Highlighted Title
                        RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.slate900,
                              height: 1.25,
                              fontFamily: 'Plus Jakarta Sans',
                            ),
                            children: [
                              TextSpan(text: page.titlePrefix),
                              TextSpan(
                                text: page.titleHighlight,
                                style: const TextStyle(
                                  color: AppColors.pinkPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              TextSpan(text: page.titleSuffix),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),
                        // Subtitle
                        Text(
                          page.description,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.slate500,
                            height: 1.5,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            // Bottom Action Area
            Padding(
              padding: const EdgeInsets.only(left: 40, right: 40, bottom: 36, top: 10),
              child: Column(
                children: [
                  // Go Now Button
                  SizedBox(
                    width: 220,
                    height: 52,
                    child: WedifyButton(
                      text: "Go Now",
                      style: WedifyButtonStyle.pinkGradient,
                      trailingIcon: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 20),
                      onPressed: () {
                        if (_currentPage == _pages.length - 1) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const AuthScreen()),
                          );
                        } else {
                          _controller.nextPage(
                            duration: const Duration(milliseconds: 350),
                            curve: Curves.easeInOut,
                          );
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Page Indicators
                  SmoothPageIndicator(
                    controller: _controller,
                    count: _pages.length,
                    effect: const ExpandingDotsEffect(
                      activeDotColor: AppColors.pinkPrimary,
                      dotColor: Color(0xFFFFD6E0),
                      dotHeight: 7,
                      dotWidth: 7,
                      expansionFactor: 3,
                      spacing: 6,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustrationCircle(OnboardingImageType imageType) {
    return Container(
      width: 260,
      height: 260,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFF0F5),
        boxShadow: [
          BoxShadow(
            color: AppColors.pinkPrimary.withValues(alpha: 0.08),
            blurRadius: 24,
            spreadRadius: 8,
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Floral Arch Header
            Positioned(
              top: 15,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  7,
                  (i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Icon(
                      Icons.filter_vintage_rounded,
                      size: 22 - (i % 2 * 4).toDouble(),
                      color: i % 2 == 0 ? AppColors.pinkPrimary.withValues(alpha: 0.8) : const Color(0xFFFF9EB5),
                    ),
                  ),
                ),
              ),
            ),
            // Floating Hearts
            Positioned(
              top: 75,
              child: Row(
                children: const [
                  Icon(Icons.favorite_rounded, size: 24, color: AppColors.pinkPrimary),
                  SizedBox(width: 8),
                  Icon(Icons.favorite_rounded, size: 18, color: Color(0xFFFF85A1)),
                ],
              ),
            ),
            // Illustration Artwork by Type
            Positioned(
              bottom: 10,
              child: _getIllustrationWidget(imageType),
            ),
          ],
        ),
      ),
    );
  }

  Widget _getIllustrationWidget(OnboardingImageType imageType) {
    switch (imageType) {
      case OnboardingImageType.weddingCouple:
        return SizedBox(
          width: 230,
          height: 170,
          child: CustomPaint(
            painter: WeddingCouplePainter(),
          ),
        );
      case OnboardingImageType.venuePlanner:
        return SizedBox(
          width: 200,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Icon(Icons.castle_rounded, size: 64, color: AppColors.pinkPrimary),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.architecture_rounded, color: AppColors.slate700, size: 28),
                  SizedBox(width: 12),
                  Icon(Icons.map_rounded, color: AppColors.pinkPrimary, size: 28),
                ],
              ),
            ],
          ),
        );
      case OnboardingImageType.invitationsCatering:
        return SizedBox(
          width: 200,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
                ),
                child: const Icon(Icons.mark_email_unread_rounded, size: 64, color: AppColors.pinkPrimary),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.restaurant_menu_rounded, color: AppColors.slate700, size: 28),
                  SizedBox(width: 12),
                  Icon(Icons.cake_rounded, color: AppColors.pinkPrimary, size: 28),
                ],
              ),
            ],
          ),
        );
    }
  }
}

enum OnboardingImageType { weddingCouple, venuePlanner, invitationsCatering }

class OnboardingSlideData {
  final String titlePrefix;
  final String titleHighlight;
  final String titleSuffix;
  final String description;
  final OnboardingImageType imageType;

  OnboardingSlideData({
    required this.titlePrefix,
    required this.titleHighlight,
    required this.titleSuffix,
    required this.description,
    required this.imageType,
  });
}

// Custom Painter to render 3D-styled Groom & Bride illustration matching image
class WeddingCouplePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = size.width / 2;

    // Groom (Left side)
    final groomBodyPaint = Paint()..color = const Color(0xFF2C3E50); // Dark Navy Suit
    final groomShirtPaint = Paint()..color = Colors.white;
    final groomTiePaint = Paint()..color = AppColors.pinkPrimary;
    final skinPaint = Paint()..color = const Color(0xFFFFDAB9);
    final hairGroomPaint = Paint()..color = const Color(0xFF1E1E1E);

    // Groom Suit Body
    final groomPath = Path()
      ..moveTo(center - 75, size.height)
      ..lineTo(center - 75, size.height - 70)
      ..cubicTo(center - 75, size.height - 95, center - 15, size.height - 95, center - 15, size.height - 70)
      ..lineTo(center - 15, size.height)
      ..close();
    canvas.drawPath(groomPath, groomBodyPaint);

    // Groom Shirt V-neck
    final groomShirtPath = Path()
      ..moveTo(center - 50, size.height - 90)
      ..lineTo(center - 45, size.height - 50)
      ..lineTo(center - 40, size.height - 90)
      ..close();
    canvas.drawPath(groomShirtPath, groomShirtPaint);

    // Groom Bowtie
    canvas.drawCircle(Offset(center - 45, size.height - 75), 4, groomTiePaint);

    // Groom Head & Glasses
    canvas.drawCircle(Offset(center - 45, size.height - 110), 22, skinPaint);
    canvas.drawCircle(Offset(center - 45, size.height - 124), 22, hairGroomPaint);

    // Glasses
    final glassesPaint = Paint()
      ..color = const Color(0xFF333333)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(center - 38, size.height - 110), 6, glassesPaint);

    // Bride (Right side)
    final brideDressPaint = Paint()..color = Colors.white;
    final veilPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);

    // Bride Dress Body
    final bridePath = Path()
      ..moveTo(center + 15, size.height)
      ..lineTo(center + 15, size.height - 70)
      ..cubicTo(center + 15, size.height - 95, center + 75, size.height - 95, center + 75, size.height - 70)
      ..lineTo(center + 75, size.height)
      ..close();
    canvas.drawPath(bridePath, brideDressPaint);

    // Bride Neck & Head
    canvas.drawCircle(Offset(center + 45, size.height - 110), 20, skinPaint);

    // Bride Hair & Tiara
    final brideHairPaint = Paint()..color = const Color(0xFF4A2E2B);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(center + 45, size.height - 115), radius: 21),
      3.14,
      3.14,
      true,
      brideHairPaint,
    );

    // Bride Veil
    final veilPath = Path()
      ..moveTo(center + 45, size.height - 130)
      ..cubicTo(center + 80, size.height - 110, center + 85, size.height - 40, center + 75, size.height - 20)
      ..lineTo(center + 45, size.height - 120)
      ..close();
    canvas.drawPath(veilPath, veilPaint);

    // Holding Hands Connection
    canvas.drawCircle(Offset(center - 5, size.height - 40), 8, skinPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

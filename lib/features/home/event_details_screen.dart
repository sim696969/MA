import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class EventDetailsScreen extends StatelessWidget {
  final String title;
  final String date;
  final String location;
  final String guests;
  final String price;
  final String imagePath;
  final String story;

  const EventDetailsScreen({
    super.key,
    this.title = "Caroline & Ethan Wedding",
    this.date = "05 Mar, 2024",
    this.location = "Grandview",
    this.guests = "250-300 Guests",
    this.price = "\$7500",
    this.imagePath = "https://images.unsplash.com/photo-1519741497674-611481863552?w=800&auto=format&fit=crop&q=80",
    this.story = "I got married at Wedify almost 3 weeks ago now and I'm still reeling from how amazing everything was. My husband and I each had multiple people tell us it was the best wedding they'd ever been to, and everything that was done for us was so meticulously thought out and special. If I had to do it all over again, I'd undoubtedly still choose Wedify!",
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.slate900),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "Wedding Events",
          style: TextStyle(
            color: AppColors.slate900,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.notifications_none_rounded, color: AppColors.slate900, size: 20),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Large Hero Image
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Image.network(
                imagePath,
                width: double.infinity,
                height: 240,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: double.infinity,
                  height: 240,
                  color: AppColors.pinkLight,
                  child: const Icon(Icons.favorite_rounded, color: AppColors.pinkPrimary, size: 64),
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Title
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 6),
            // Date / Location / Guests
            Text(
              "$date; $location; $guests;",
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.slate500,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            // Price Tag
            Row(
              children: [
                Text(
                  price,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.pinkPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                const Text(
                  "(Total Cost)",
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.slate400,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            // Story Section Title
            const Text(
              "Wonderful Wedding Party",
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: AppColors.slate900,
              ),
            ),
            const SizedBox(height: 12),
            // Story Paragraph
            Text(
              story,
              style: const TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.slate600,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      // Floating Bottom Actions (Close, Heart, Star)
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            // Close Button
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.close_rounded, color: AppColors.slate600, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            // Favorite Pink Heart Button
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.pinkGradientStart, AppColors.pinkGradientEnd],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.pinkPrimary.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.favorite_rounded, color: Colors.white, size: 28),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Added to your saved weddings!"),
                      backgroundColor: AppColors.pinkPrimary,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
            // Star Button
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.slate100,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.star_rounded, color: AppColors.slate600, size: 22),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Event starred!"),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

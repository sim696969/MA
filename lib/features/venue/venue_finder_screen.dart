import 'package:flutter/material.dart';
import '../../widgets/wedify_card.dart';
import '../../widgets/wedify_button.dart';

class VenueFinderScreen extends StatefulWidget {
  const VenueFinderScreen({super.key});

  @override
  State<VenueFinderScreen> createState() => _VenueFinderScreenState();
}

class _VenueFinderScreenState extends State<VenueFinderScreen> {
  String _selectedState = "Kuala Lumpur";
  final List<String> _states = ["Kuala Lumpur", "Penang", "Johor", "Selangor", "Sarawak", "Sabah"];
  bool _isMapView = false;

  final List<Venue> _venues = [
    Venue(
      name: "Grand Hyatt KL",
      type: "Banquet Hall",
      location: "KLCC, Kuala Lumpur",
      rating: 4.8,
      price: "RM 250/pax",
      imageUrl: "https://images.unsplash.com/photo-1519167758481-83f550bb49b3?auto=format&fit=crop&w=800&q=80",
    ),
    Venue(
      name: "Suffolk House",
      type: "Garden / Heritage",
      location: "Air Itam, Penang",
      rating: 4.7,
      price: "RM 180/pax",
      imageUrl: "https://images.unsplash.com/photo-1519741497674-611481863552?auto=format&fit=crop&w=800&q=80",
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Venue Finder"),
        actions: [
          IconButton(
            icon: Icon(_isMapView ? Icons.list : Icons.map),
            onPressed: () => setState(() => _isMapView = !_isMapView),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedState,
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      hintText: "Select State",
                    ),
                    items: _states.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                    onChanged: (val) => setState(() => _selectedState = val!),
                  ),
                ),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {},
                ),
              ],
            ),
          ),
          Expanded(
            child: _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _venues.length,
      itemBuilder: (context, index) {
        final venue = _venues[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 16.0),
          child: WedifyCard(
            padding: EdgeInsets.zero,
            onTap: () => _showVenueDetails(venue),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 180,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    image: DecorationImage(image: NetworkImage(venue.imageUrl), fit: BoxFit.cover),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              Text(" ${venue.rating}", style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(venue.type, style: TextStyle(color: Theme.of(context).colorScheme.secondary, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 4),
                      Text(venue.location, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                      const SizedBox(height: 12),
                      Text(venue.price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMapView() {
    return Container(
      color: Colors.grey[200],
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.map_outlined, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text("Google Maps Integration Placeholder", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
            Text("// TODO: Insert your Google Maps API key here", style: TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showVenueDetails(Venue venue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              height: 250,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                image: DecorationImage(image: NetworkImage(venue.imageUrl), fit: BoxFit.cover),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(venue.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    const SizedBox(height: 8),
                    Text(venue.location, style: const TextStyle(color: Colors.grey)),
                    const SizedBox(height: 24),
                    const Text(
                      "About this venue",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Experience luxury and elegance at one of Malaysia's most prestigious wedding venues. Offering full service catering, state-of-the-art lighting, and a dedicated events team.",
                      style: TextStyle(color: Colors.grey, height: 1.5),
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Starting from", style: TextStyle(color: Colors.grey, fontSize: 12)),
                              Text(venue.price, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
                            ],
                          ),
                        ),
                        Expanded(
                          child: WedifyButton(
                            text: "BOOK NOW",
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Booking request sent!")),
                              );
                            },
                          ),
                        ),
                      ],
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
}

class Venue {
  final String name;
  final String type;
  final String location;
  final double rating;
  final String price;
  final String imageUrl;

  Venue({
    required this.name,
    required this.type,
    required this.location,
    required this.rating,
    required this.price,
    required this.imageUrl,
  });
}

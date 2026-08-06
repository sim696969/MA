import 'package:flutter/material.dart';
import '../../widgets/wedify_card.dart';
import 'invitation_editor_screen.dart';

class InvitationGalleryScreen extends StatelessWidget {
  const InvitationGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<InvitationTemplate> templates = [
      InvitationTemplate(name: "Modern Minimalist", type: "Modern", imageUrl: "https://images.unsplash.com/photo-1607190074257-dd4b7af0309f?auto=format&fit=crop&w=800&q=80"),
      InvitationTemplate(name: "Royal Gold", type: "Luxury", imageUrl: "https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?auto=format&fit=crop&w=800&q=80"),
      InvitationTemplate(name: "Garden Bloom", type: "Floral", imageUrl: "https://images.unsplash.com/photo-1510076857177-7470076d4098?auto=format&fit=crop&w=800&q=80"),
      InvitationTemplate(name: "Traditional Batik", type: "Cultural", imageUrl: "https://images.unsplash.com/photo-1522673607200-1648832cee98?auto=format&fit=crop&w=800&q=80"),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text("Invitation Templates")),
      body: GridView.builder(
        padding: const EdgeInsets.all(24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.7,
        ),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];
          return WedifyCard(
            padding: EdgeInsets.zero,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => InvitationEditorScreen(template: template)),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                      image: DecorationImage(image: NetworkImage(template.imageUrl), fit: BoxFit.cover),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(template.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(template.type, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class InvitationTemplate {
  final String name;
  final String type;
  final String imageUrl;

  InvitationTemplate({required this.name, required this.type, required this.imageUrl});
}

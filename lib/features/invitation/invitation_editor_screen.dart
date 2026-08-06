import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../widgets/wedify_button.dart';
import 'invitation_gallery_screen.dart';

class InvitationEditorScreen extends StatefulWidget {
  final InvitationTemplate template;

  const InvitationEditorScreen({super.key, required this.template});

  @override
  State<InvitationEditorScreen> createState() => _InvitationEditorScreenState();
}

class _InvitationEditorScreenState extends State<InvitationEditorScreen> {
  final TextEditingController _nameController = TextEditingController(text: "Sarah & John");
  final TextEditingController _dateController = TextEditingController(text: "12th December 2024");
  final TextEditingController _locationController = TextEditingController(text: "Grand Hyatt, KL");

  void _shareViaEmail() async {
    final String subject = Uri.encodeComponent("Wedding Invitation: ${_nameController.text}");
    final String body = Uri.encodeComponent(
      "You are cordially invited to our wedding!\n\n"
      "Date: ${_dateController.text}\n"
      "Location: ${_locationController.text}\n\n"
      "Sent via Wedify App."
    );
    
    final Uri emailUri = Uri.parse("mailto:?subject=$subject&body=$body");
    
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open email client")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Invitation")),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              height: 300,
              width: double.infinity,
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(image: NetworkImage(widget.template.imageUrl), fit: BoxFit.cover),
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10)),
                ],
              ),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.black.withOpacity(0.3),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(_nameController.text, style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w300)),
                      const SizedBox(height: 8),
                      Text(_dateController.text, style: const TextStyle(color: Colors.white, fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Invitation Details", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _nameController,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(labelText: "Couples Names"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _dateController,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(labelText: "Date & Time"),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _locationController,
                    onChanged: (v) => setState(() {}),
                    decoration: const InputDecoration(labelText: "Venue Location"),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: WedifyButton(
                      text: "SHARE VIA EMAIL",
                      onPressed: _shareViaEmail,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: WedifyButton(
                      text: "Preview PDF",
                      style: WedifyButtonStyle.outline,
                      onPressed: () {},
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/guest_invitation_model.dart';
import '../../services/database_service.dart';
import '../../services/wedding_project_provider.dart';

class InvitationTemplateOption {
  final String id;
  final String name;
  final String type;
  final String description;
  final String imageUrl;

  const InvitationTemplateOption({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.imageUrl,
  });
}

class InvitationGalleryScreen extends ConsumerStatefulWidget {
  const InvitationGalleryScreen({super.key});

  @override
  ConsumerState<InvitationGalleryScreen> createState() =>
      _InvitationGalleryScreenState();
}

class _InvitationGalleryScreenState
    extends ConsumerState<InvitationGalleryScreen> {
  final DatabaseService _dbService = DatabaseService();

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _customMessageController =
      TextEditingController(text: "We request the pleasure of your company to celebrate our wedding.");
  final TextEditingController _weddingDateTimeController =
      TextEditingController(text: "Saturday, 12 December 2026 at 5:00 PM");
  final TextEditingController _venueAddressController =
      TextEditingController(text: "Grand Hyatt Kuala Lumpur, Grand Ballroom");
  final TextEditingController _hostNamesController =
      TextEditingController(text: "Sarah & John");

  // Local state
  final List<GuestInvitationModel> _localGuests = [];
  bool _isTemplateSectionExpanded = false;
  bool _isCustomizingDetails = false;
  bool _isAddingGuest = false;
  bool _isSending = false;
  StreamSubscription<List<GuestInvitationModel>>? _guestSubscription;

  // Available Templates
  final List<InvitationTemplateOption> _templates = const [
    InvitationTemplateOption(
      id: "minimalist",
      name: "Modern Minimalist",
      type: "Modern Monochrome",
      description: "Clean typography with bold minimalist black lines and ample white space.",
      imageUrl:
          "https://images.unsplash.com/photo-1607190074257-dd4b7af0309f?auto=format&fit=crop&w=800&q=80",
    ),
    InvitationTemplateOption(
      id: "royal_gold",
      name: "Royal Gold",
      type: "Luxury Black & Gold",
      description: "Opulent classic framing with timeless serif aesthetics and regal motifs.",
      imageUrl:
          "https://images.unsplash.com/photo-1515934751635-c81c6bc9a2d8?auto=format&fit=crop&w=800&q=80",
    ),
    InvitationTemplateOption(
      id: "garden_bloom",
      name: "Garden Bloom",
      type: "Botanical Monochrome",
      description: "Delicate botanical illustrations with subtle editorial elegance.",
      imageUrl:
          "https://images.unsplash.com/photo-1510076857177-7470076d4098?auto=format&fit=crop&w=800&q=80",
    ),
    InvitationTemplateOption(
      id: "traditional_batik",
      name: "Traditional Batik",
      type: "Heritage Motif",
      description: "Intricate traditional geometric batik prints in high-contrast styling.",
      imageUrl:
          "https://images.unsplash.com/photo-1522673607200-1648832cee98?auto=format&fit=crop&w=800&q=80",
    ),
  ];

  late InvitationTemplateOption _selectedTemplate;

  @override
  void initState() {
    super.initState();
    _selectedTemplate = _templates.first;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initProjectDefaults();
      _subscribeToFirestoreGuests();
    });
  }

  void _initProjectDefaults() {
    final project = ref.read(weddingProjectProvider);
    if (project.weddingDate != null) {
      final dateStr =
          "${project.weddingDate!.day}/${project.weddingDate!.month}/${project.weddingDate!.year}";
      final timeStr = project.weddingTime ?? "5:00 PM";
      _weddingDateTimeController.text = "$dateStr at $timeStr";
    }
    if (project.selectedVenueName != null &&
        project.selectedVenueName!.isNotEmpty) {
      _venueAddressController.text = project.selectedVenueName!;
    }
  }

  void _subscribeToFirestoreGuests() {
    final project = ref.read(weddingProjectProvider);
    final projectId = project.id.isNotEmpty ? project.id : 'project_1';

    _guestSubscription?.cancel();
    _guestSubscription = _dbService.streamGuestInvitations(projectId: projectId).listen(
      (firestoreList) {
        if (mounted) {
          setState(() {
            _localGuests.clear();
            _localGuests.addAll(firestoreList);
          });
        }
      },
      onError: (_) {
        // Keep existing local list if offline
      },
    );
  }

  @override
  void dispose() {
    _guestSubscription?.cancel();
    _nameController.dispose();
    _addressController.dispose();
    _customMessageController.dispose();
    _weddingDateTimeController.dispose();
    _venueAddressController.dispose();
    _hostNamesController.dispose();
    super.dispose();
  }

  Future<void> _addGuest() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isAddingGuest = true);

    final project = ref.read(weddingProjectProvider);
    final projectId = project.id.isNotEmpty ? project.id : 'project_1';
    final newId = 'guest_${DateTime.now().millisecondsSinceEpoch}';

    final newGuest = GuestInvitationModel(
      id: newId,
      guestName: _nameController.text.trim(),
      guestAddress: _addressController.text.trim(),
      templateId: _selectedTemplate.id,
      templateName: _selectedTemplate.name,
      customTemplateData: {
        'customMessage': _customMessageController.text.trim(),
        'weddingDateTime': _weddingDateTimeController.text.trim(),
        'venueAddress': _venueAddressController.text.trim(),
        'hostNames': _hostNamesController.text.trim(),
      },
      status: 'draft',
      createdAt: DateTime.now(),
    );

    try {
      await _dbService.saveGuestInvitation(
        projectId: projectId,
        guest: newGuest,
      );

      // Also update project state if first invitation
      ref.read(weddingProjectProvider.notifier).updateInvitation(
            invitationName: _selectedTemplate.name,
            fee: 150.0,
            isCompleted: true,
          );

      if (mounted) {
        _nameController.clear();
        _addressController.clear();
        setState(() {
          // If Firestore stream didn't update immediately, add locally
          if (!_localGuests.any((g) => g.id == newGuest.id)) {
            _localGuests.insert(0, newGuest);
          }
          _isTemplateSectionExpanded = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
              side: const BorderSide(color: Colors.white, width: 1),
            ),
            content: Text(
              "Guest added with ${_selectedTemplate.name}!",
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Fallback local addition if network fails
        setState(() {
          _localGuests.insert(0, newGuest);
          _nameController.clear();
          _addressController.clear();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            content: Text(
              "Added locally (offline mode).",
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isAddingGuest = false);
      }
    }
  }

  Future<void> _deleteGuest(GuestInvitationModel guest, int index) async {
    final project = ref.read(weddingProjectProvider);
    final projectId = project.id.isNotEmpty ? project.id : 'project_1';

    setState(() {
      _localGuests.removeAt(index);
    });

    try {
      await _dbService.deleteGuestInvitation(
        projectId: projectId,
        guestId: guest.id,
      );
    } catch (_) {
      // Ignored
    }
  }

  Future<void> _sendAllInvitations() async {
    if (_localGuests.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.black,
          content: Text(
            "Please add at least one guest before sending.",
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
      return;
    }

    setState(() => _isSending = true);

    final project = ref.read(weddingProjectProvider);
    final projectId = project.id.isNotEmpty ? project.id : 'project_1';

    try {
      final updatedCount = await _dbService.sendAllInvitationsBatch(
        projectId: projectId,
        guests: _localGuests,
      );

      // Local optimistic update
      setState(() {
        for (int i = 0; i < _localGuests.length; i++) {
          _localGuests[i] = _localGuests[i].copyWith(status: 'sent');
        }
      });

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: const BorderSide(color: Colors.black, width: 2),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  "SUCCESS",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                    fontSize: 18,
                  ),
                ),
              ],
            ),
            content: Text(
              "Invitations Sent Successfully!\n\n$updatedCount guest invitation(s) have been processed and dispatched to Firestore.",
              style: GoogleFonts.inter(
                color: Colors.black87,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(
                  "CONTINUE",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.black,
            content: Text(
              "Error dispatching invitations: $e",
              style: GoogleFonts.inter(color: Colors.white),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  void _previewInvitation(GuestInvitationModel guest) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        side: BorderSide(color: Colors.black, width: 2),
      ),
      builder: (context) {
        final data = guest.customTemplateData;
        final template = _templates.firstWhere(
          (t) => t.id == guest.templateId,
          orElse: () => _templates.first,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "CARD PREVIEW",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.2,
                      fontSize: 16,
                      color: Colors.black,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.black),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(color: Colors.black, thickness: 1.5),
              const SizedBox(height: 16),
              // Wireframe styled digital card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.black, width: 2),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black,
                      offset: Offset(4, 4),
                      blurRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      template.name.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 2.0,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['hostNames'] ?? "Sarah & John",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "INVITES",
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                        color: Colors.black45,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      guest.guestName,
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      data['customMessage'] ??
                          "We request the pleasure of your company to celebrate our wedding.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: Colors.black87,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Divider(color: Colors.black12, thickness: 1),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today_outlined, size: 16, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['weddingDateTime'] ?? "12 December 2026",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16, color: Colors.black),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            data['venueAddress'] ?? "Grand Hyatt KL",
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _shareGuestCardViaEmail(guest);
                  },
                  icon: const Icon(Icons.email_outlined, color: Colors.white),
                  label: Text(
                    "SHARE VIA EMAIL",
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.0,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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

  void _shareGuestCardViaEmail(GuestInvitationModel guest) async {
    final data = guest.customTemplateData;
    final subject = Uri.encodeComponent("Wedding Invitation for ${guest.guestName}");
    final body = Uri.encodeComponent(
      "Dear ${guest.guestName},\n\n"
      "${data['customMessage'] ?? 'You are cordially invited to celebrate our wedding!'}\n\n"
      "Date & Time: ${data['weddingDateTime'] ?? 'TBD'}\n"
      "Venue: ${data['venueAddress'] ?? 'TBD'}\n\n"
      "With Love,\n"
      "${data['hostNames'] ?? 'Sarah & John'}\n\n"
      "-- Sent via Wedify App",
    );

    final emailUri = Uri.parse("mailto:${guest.guestAddress}?subject=$subject&body=$body");
    if (await canLaunchUrl(emailUri)) {
      await launchUrl(emailUri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final guestsCount = _localGuests.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFFFF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 20,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: Colors.black, height: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          "INVITATIONS & GUESTS",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 18,
            letterSpacing: 1.0,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Summary / Counter Badge
              _buildHeaderCounter(guestsCount),
              const SizedBox(height: 24),

              // Unified Guest & Template Form
              _buildGuestCreationForm(),
              const SizedBox(height: 32),

              // Invited Guests List Header
              _buildGuestListHeader(guestsCount),
              const SizedBox(height: 16),

              // Guests List View
              _buildGuestListSection(),
              const SizedBox(height: 32),

              // Send Invitations Bottom Action
              _buildSendActionSection(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCounter(int guestsCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(3, 3),
            blurRadius: 0,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "TOTAL INVITED",
                style: GoogleFonts.inter(
                  color: Colors.black54,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                "Guest Management",
                style: GoogleFonts.inter(
                  color: Colors.black,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "$guestsCount / 200",
              style: GoogleFonts.inter(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuestCreationForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "ADD NEW GUEST & TEMPLATE",
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontWeight: FontWeight.w900,
                    fontSize: 14,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Input: Guest Name
            _buildMonochromeTextField(
              controller: _nameController,
              label: "GUEST FULL NAME",
              hintText: "e.g., Alexander Wright",
              icon: Icons.person_outline,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? "Please enter guest name" : null,
            ),
            const SizedBox(height: 14),

            // Input: Guest Email / Address
            _buildMonochromeTextField(
              controller: _addressController,
              label: "GUEST ADDRESS / EMAIL",
              hintText: "e.g., alex.wright@example.com",
              icon: Icons.alternate_email,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? "Please enter address or email"
                  : null,
            ),
            const SizedBox(height: 16),

            // Template Selector Trigger
            _buildTemplateSelectorButton(),
            const SizedBox(height: 12),

            // Template Expansion Section
            if (_isTemplateSectionExpanded) ...[
              _buildTemplatePickerGrid(),
              const SizedBox(height: 16),
            ],

            // Template Customization Accordion
            _buildCustomizationAccordion(),
            const SizedBox(height: 20),

            // Add Guest Action Button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _isAddingGuest ? null : _addGuest,
                icon: _isAddingGuest
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(Icons.add, color: Colors.white, size: 20),
                label: Text(
                  _isAddingGuest ? "SAVING..." : "+ ADD GUEST & INVITATION",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    fontSize: 14,
                    color: Colors.white,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonochromeTextField({
    required TextEditingController controller,
    required String label,
    required String hintText,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: GoogleFonts.inter(
            color: Colors.black,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: GoogleFonts.inter(
              color: Colors.grey[500],
              fontSize: 13,
            ),
            prefixIcon: Icon(icon, color: Colors.black, size: 20),
            filled: true,
            fillColor: const Color(0xFFFAFAFA),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.black, width: 2.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildTemplateSelectorButton() {
    return InkWell(
      onTap: () {
        setState(() {
          _isTemplateSectionExpanded = !_isTemplateSectionExpanded;
        });
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.style_outlined, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "SELECTED TEMPLATE",
                      style: GoogleFonts.inter(
                        color: Colors.white70,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                      ),
                    ),
                    Text(
                      _selectedTemplate.name,
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            Icon(
              _isTemplateSectionExpanded
                  ? Icons.keyboard_arrow_up
                  : Icons.keyboard_arrow_down,
              color: Colors.white,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplatePickerGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "CHOOSE INVITATION STYLE:",
          style: GoogleFonts.inter(
            color: Colors.black,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 10),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.85,
          ),
          itemCount: _templates.length,
          itemBuilder: (context, index) {
            final t = _templates[index];
            final isSelected = t.id == _selectedTemplate.id;

            return InkWell(
              onTap: () {
                setState(() {
                  _selectedTemplate = t;
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.black,
                    width: isSelected ? 2.5 : 1.5,
                  ),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: Colors.black,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ]
                      : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          image: DecorationImage(
                            image: NetworkImage(t.imageUrl),
                            fit: BoxFit.cover,
                          ),
                        ),
                        child: Align(
                          alignment: Alignment.topRight,
                          child: isSelected
                              ? Container(
                                  margin: const EdgeInsets.all(6),
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    size: 14,
                                    color: Colors.white,
                                  ),
                                )
                              : null,
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t.name,
                            style: GoogleFonts.inter(
                              color: isSelected ? Colors.white : Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            t.type,
                            style: GoogleFonts.inter(
                              color:
                                  isSelected ? Colors.white70 : Colors.black54,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomizationAccordion() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAFAFA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black, width: 1.5),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isCustomizingDetails,
          onExpansionChanged: (expanded) {
            setState(() => _isCustomizingDetails = expanded);
          },
          tilePadding: const EdgeInsets.symmetric(horizontal: 14),
          leading: const Icon(Icons.tune, color: Colors.black, size: 20),
          title: Text(
            "CUSTOMIZE INVITATION DETAILS",
            style: GoogleFonts.inter(
              color: Colors.black,
              fontWeight: FontWeight.w800,
              fontSize: 12,
              letterSpacing: 0.8,
            ),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 16),
          children: [
            const Divider(color: Colors.black26, thickness: 1),
            const SizedBox(height: 10),
            _buildMonochromeTextField(
              controller: _hostNamesController,
              label: "COUPLE / HOST NAMES",
              hintText: "e.g., Sarah & John",
              icon: Icons.favorite_border,
            ),
            const SizedBox(height: 12),
            _buildMonochromeTextField(
              controller: _weddingDateTimeController,
              label: "DATE & TIME",
              hintText: "e.g., Saturday, 12 December 2026 at 5:00 PM",
              icon: Icons.calendar_today_outlined,
            ),
            const SizedBox(height: 12),
            _buildMonochromeTextField(
              controller: _venueAddressController,
              label: "VENUE ADDRESS",
              hintText: "e.g., Grand Hyatt KL",
              icon: Icons.location_on_outlined,
            ),
            const SizedBox(height: 12),
            _buildMonochromeTextField(
              controller: _customMessageController,
              label: "CUSTOM INVITATION MESSAGE",
              hintText: "Personal note for guest",
              icon: Icons.message_outlined,
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuestListHeader(int count) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(Icons.people, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 10),
            Text(
              "INVITED GUESTS",
              style: GoogleFonts.inter(
                color: Colors.black,
                fontWeight: FontWeight.w900,
                fontSize: 15,
                letterSpacing: 1.0,
              ),
            ),
          ],
        ),
        Text(
          "$count Guest${count == 1 ? '' : 's'}",
          style: GoogleFonts.inter(
            color: Colors.black54,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildGuestListSection() {
    if (_localGuests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFA),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black, width: 2),
          boxShadow: const [
            BoxShadow(
              color: Colors.black,
              offset: Offset(3, 3),
              blurRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            const Icon(Icons.mail_outline_rounded, size: 48, color: Colors.black),
            const SizedBox(height: 12),
            Text(
              "NO GUESTS ADDED YET",
              style: GoogleFonts.inter(
                color: Colors.black,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Fill in the guest details above and choose a template to create cards.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: Colors.black54,
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: _localGuests.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final guest = _localGuests[index];
        final isSent = guest.status == 'sent';

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black, width: 2),
            boxShadow: const [
              BoxShadow(
                color: Colors.black,
                offset: Offset(3, 3),
                blurRadius: 0,
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: isSent ? Colors.black : Colors.white,
              foregroundColor: isSent ? Colors.white : Colors.black,
              radius: 20,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  guest.guestName.isNotEmpty
                      ? guest.guestName[0].toUpperCase()
                      : "?",
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    guest.guestName,
                    style: GoogleFonts.inter(
                      color: Colors.black,
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isSent ? Colors.black : const Color(0xFFEEEEEE),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black, width: 1),
                  ),
                  child: Text(
                    isSent ? "SENT" : "DRAFT",
                    style: GoogleFonts.inter(
                      color: isSent ? Colors.white : Colors.black,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  guest.guestAddress,
                  style: GoogleFonts.inter(
                    color: Colors.black54,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFAFAFA),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.black38, width: 1),
                  ),
                  child: Text(
                    "Template: ${guest.templateName}",
                    style: GoogleFonts.inter(
                      color: Colors.black87,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_red_eye_outlined, color: Colors.black),
                  tooltip: "Preview Card",
                  onPressed: () => _previewInvitation(guest),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.black54),
                  tooltip: "Remove Guest",
                  onPressed: () => _deleteGuest(guest, index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSendActionSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black, width: 2),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            offset: Offset(0, 8),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "BATCH DISPATCH",
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            "Sync and dispatch digital invitation status for all configured guests in Firestore.",
            style: GoogleFonts.inter(
              color: Colors.white70,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _isSending ? null : _sendAllInvitations,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                      ),
                    )
                  : Text(
                      "SEND INVITATIONS (${_localGuests.length})",
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.2,
                        fontSize: 14,
                        color: Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

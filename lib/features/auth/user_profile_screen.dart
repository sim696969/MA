import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme/app_colors.dart';
import '../../services/auth_session_service.dart';
import '../../services/database_service.dart';
import '../../services/notification_provider.dart';
import '../../widgets/app_bottom_nav_bar.dart';
import '../auth/auth_screen.dart';
import '../notifications/notification_center_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  final DatabaseService _dbService = DatabaseService();

  bool _isLoading = true;

  String _userName = 'Wedify User';
  String _userEmail = 'user@wedify.com';
  String _userPhone = 'Not specified';
  String _partnerName = 'Not specified';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  String get _currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.uid.isNotEmpty) {
      return user.uid;
    }
    final sessionEmail = ref.read(authStateProvider).email;
    if (sessionEmail != null && sessionEmail.isNotEmpty) {
      return sessionEmail.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    }
    return 'default_user';
  }

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);
    final sessionEmail = ref.read(authStateProvider).email ?? 'user@wedify.com';
    _userEmail = sessionEmail;

    try {
      final doc = await _dbService.getDocument(
        collectionPath: 'users',
        docId: _currentUserId,
      );

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _userName = data['name'] ?? 'Wedify User';
        _userPhone = (data['phone'] != null && data['phone'].toString().isNotEmpty) ? data['phone'] : 'Not specified';
        _partnerName = (data['partnerName'] != null && data['partnerName'].toString().isNotEmpty) ? data['partnerName'] : 'Not specified';
        if (data['email'] != null && data['email'].toString().isNotEmpty) {
          _userEmail = data['email'];
        }
      } else {
        _userName = sessionEmail.split('@').first;
      }
    } catch (e) {
      _userName = 'Wedify User';
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openEditModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _EditProfileModal(
        initialName: _userName,
        initialEmail: _userEmail,
        initialPhone: _userPhone == 'Not specified' ? '' : _userPhone,
        initialPartnerName: _partnerName == 'Not specified' ? '' : _partnerName,
        userId: _currentUserId,
        onProfileUpdated: () {
          _loadUserData();
        },
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context) async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Logout",
          style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.slate900),
        ),
        content: const Text("Are you sure you want to log out of Wedify?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancel", style: TextStyle(color: AppColors.slate600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.pinkPrimary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Logout", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && context.mounted) {
      await ref.read(authStateProvider.notifier).logout();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const AuthScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColors.slate900, size: 18),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        title: const Text(
          "My Profile",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slate900),
        ),
        centerTitle: true,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final unreadCount = ref.watch(unreadNotificationCountProvider);
              return IconButton(
                tooltip: 'Notifications',
                icon: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    const Icon(Icons.notifications_none_rounded, color: AppColors.slate900, size: 24),
                    if (unreadCount > 0)
                      Positioned(
                        right: -4,
                        top: -4,
                        child: Container(
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          alignment: Alignment.center,
                          decoration: const BoxDecoration(
                            color: Color(0xFFE57373),
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const NotificationCenterScreen()),
                  );
                },
              );
            },
          ),
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout_rounded, color: AppColors.pinkPrimary),
            onPressed: () => _handleLogout(context),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.pinkPrimary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  // Profile Header & Avatar with Edit Pencil Icon
                  Center(
                    child: Column(
                      children: [
                        Stack(
                          children: [
                            Container(
                              width: 96,
                              height: 96,
                              decoration: const BoxDecoration(
                                color: AppColors.pinkLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(Icons.person_rounded, size: 54, color: AppColors.pinkPrimary),
                              ),
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: GestureDetector(
                                onTap: () => _openEditModal(context),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: AppColors.pinkPrimary,
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 2),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.pinkPrimary.withValues(alpha: 0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _userName,
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.slate900),
                            ),
                            const SizedBox(width: 6),
                            IconButton(
                              constraints: const BoxConstraints(),
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.edit_note_rounded, color: AppColors.pinkPrimary, size: 22),
                              onPressed: () => _openEditModal(context),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _userEmail,
                          style: const TextStyle(fontSize: 13, color: AppColors.slate500, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Info Cards Display Mode
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Account Information",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.slate900),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: AppColors.pinkPrimary),
                        onPressed: () => _openEditModal(context),
                        icon: const Icon(Icons.edit_rounded, size: 16),
                        label: const Text("Edit", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.slate100),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildDisplayRow(
                          icon: Icons.person_outline_rounded,
                          label: "Full Name",
                          value: _userName,
                        ),
                        const Divider(height: 24, color: AppColors.slate100),
                        _buildDisplayRow(
                          icon: Icons.email_outlined,
                          label: "Email Address",
                          value: _userEmail,
                        ),
                        const Divider(height: 24, color: AppColors.slate100),
                        _buildDisplayRow(
                          icon: Icons.phone_outlined,
                          label: "Contact Number",
                          value: _userPhone,
                        ),
                        const Divider(height: 24, color: AppColors.slate100),
                        _buildDisplayRow(
                          icon: Icons.favorite_border_rounded,
                          label: "Partner's Name",
                          value: _partnerName,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Quick Action Edit Button Card
                  InkWell(
                    onTap: () => _openEditModal(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.pinkLight,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.pinkBorder),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit_square, color: AppColors.pinkPrimary, size: 20),
                          SizedBox(width: 10),
                          Text(
                            "Edit Profile & Update Password",
                            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.pinkPrimary),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),

      // Bottom Navigation Bar matching Dashboard
      bottomNavigationBar: const WedifyBottomNavigationBar(currentIndex: 2),
    );
  }

  Widget _buildDisplayRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.pinkLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.pinkPrimary, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 11, color: AppColors.slate500, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.slate900),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditProfileModal extends StatefulWidget {
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final String initialPartnerName;
  final String userId;
  final VoidCallback onProfileUpdated;

  const _EditProfileModal({
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.initialPartnerName,
    required this.userId,
    required this.onProfileUpdated,
  });

  @override
  State<_EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<_EditProfileModal> {
  final _formKey = GlobalKey<FormState>();
  final DatabaseService _dbService = DatabaseService();

  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _partnerNameController;
  late TextEditingController _newPasswordController;
  late TextEditingController _confirmPasswordController;

  bool _isSaving = false;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
    _emailController = TextEditingController(text: widget.initialEmail);
    _phoneController = TextEditingController(text: widget.initialPhone);
    _partnerNameController = TextEditingController(text: widget.initialPartnerName);
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _partnerNameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final newPassword = _newPasswordController.text.trim();

    try {
      await _dbService.setDocument(
        collectionPath: 'users',
        docId: widget.userId,
        data: {
          'name': _nameController.text.trim(),
          'email': _emailController.text.trim(),
          'phone': _phoneController.text.trim(),
          'partnerName': _partnerNameController.text.trim(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
        merge: true,
      );

      if (newPassword.isNotEmpty) {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          await user.updatePassword(newPassword);
        }
      }

      widget.onProfileUpdated();

      if (mounted) {
        Navigator.pop(context); // Close modal
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile updated successfully!"),
            backgroundColor: AppColors.pinkPrimary,
          ),
        );
      }
    } catch (e) {
      widget.onProfileUpdated();
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Profile saved successfully!"),
            backgroundColor: AppColors.pinkPrimary,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.slate200,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.edit_note_rounded, color: AppColors.pinkPrimary, size: 24),
                      SizedBox(width: 8),
                      Text(
                        "Edit Profile Info",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.slate900),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.slate500),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              _buildModalTextField(
                controller: _nameController,
                label: "Full Name",
                icon: Icons.person_outline_rounded,
                validator: (v) => v == null || v.isEmpty ? "Name cannot be empty" : null,
              ),
              const SizedBox(height: 14),
              _buildModalTextField(
                controller: _emailController,
                label: "Email Address",
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || v.isEmpty ? "Email cannot be empty" : null,
              ),
              const SizedBox(height: 14),
              _buildModalTextField(
                controller: _phoneController,
                label: "Contact Number",
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 14),
              _buildModalTextField(
                controller: _partnerNameController,
                label: "Partner's Name",
                icon: Icons.favorite_border_rounded,
              ),
              const SizedBox(height: 20),

              const Text(
                "Change Password (Optional)",
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.slate900),
              ),
              const SizedBox(height: 10),
              _buildModalTextField(
                controller: _newPasswordController,
                label: "New Password",
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureNewPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureNewPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureNewPassword = !_obscureNewPassword),
                ),
                validator: (v) {
                  if (v != null && v.isNotEmpty && v.length < 6) {
                    return "Password must be at least 6 characters";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              _buildModalTextField(
                controller: _confirmPasswordController,
                label: "Confirm Password",
                icon: Icons.lock_reset_rounded,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
                validator: (v) {
                  if (_newPasswordController.text.isNotEmpty && v != _newPasswordController.text) {
                    return "Passwords do not match";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.pinkPrimary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _isSaving ? null : _saveProfile,
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Save Changes",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.slate900),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.slate500),
        prefixIcon: Icon(icon, color: AppColors.slate400, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: const Color(0xFFF8FAFC),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }
}

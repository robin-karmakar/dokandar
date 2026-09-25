import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import 'auth_gate.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _phoneController = TextEditingController();

  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _isLoadingProfile = true;
  bool _isSavingProfile = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final data = await _firestoreService.getShopProfile();
    _shopNameController.text = data['shopName'] ?? '';
    _ownerNameController.text = data['ownerName'] ?? '';
    _addressController.text = data['address'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    if (mounted) setState(() => _isLoadingProfile = false);
  }

  Future<void> _saveProfile() async {
    setState(() => _isSavingProfile = true);
    await _firestoreService.updateShopProfile(
      shopName: _shopNameController.text.trim(),
      ownerName: _ownerNameController.text.trim(),
      address: _addressController.text.trim(),
      phone: _phoneController.text.trim(),
    );
    if (mounted) {
      setState(() => _isSavingProfile = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Profile updated successfully'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    bool isSaving = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Current Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'New Password',
                  prefixIcon: const Icon(Icons.lock_reset_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            isSaving
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final current = currentPasswordController.text.trim();
                      final newPass = newPasswordController.text.trim();

                      if (current.isEmpty || newPass.isEmpty) {
                        setDialogState(() => errorText = 'Please fill both fields');
                        return;
                      }

                      setDialogState(() {
                        isSaving = true;
                        errorText = null;
                      });

                      final error = await _authService.changePassword(
                        currentPassword: current,
                        newPassword: newPass,
                      );

                      if (error != null) {
                        setDialogState(() {
                          isSaving = false;
                          errorText = error;
                        });
                      } else {
                        if (context.mounted) {
                          Navigator.pop(context);
                          ScaffoldMessenger.of(this.context).showSnackBar(
                            SnackBar(
                              content: const Text('Password changed successfully'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          );
                        }
                      }
                    },
                    child: const Text('Update'),
                  ),
          ],
        ),
      ),
    );
  }

  void _showDeleteAccountDialog() {
    final passwordController = TextEditingController();
    bool isDeleting = false;
    String? errorText;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.red),
              SizedBox(width: 8),
              Text('Delete Account', style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This will permanently delete your account and ALL shop data '
                '(products, sales, expenses). This action cannot be undone.',
                style: TextStyle(fontSize: 13, color: Colors.black87),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: passwordController,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: 'Confirm Password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              if (errorText != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(errorText!, style: const TextStyle(color: Colors.red, fontSize: 13)),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            isDeleting
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                  )
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      final password = passwordController.text.trim();
                      if (password.isEmpty) {
                        setDialogState(() => errorText = 'Please enter your password');
                        return;
                      }

                      setDialogState(() {
                        isDeleting = true;
                        errorText = null;
                      });

                      await _firestoreService.deleteAllShopData();
                      final error = await _authService.deleteAccount(password: password);

                      if (error != null) {
                        setDialogState(() {
                          isDeleting = false;
                          errorText = error;
                        });
                      } else if (context.mounted) {
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const AuthGate()),
                          (route) => false,
                        );
                      }
                    },
                    child: const Text('Delete Permanently'),
                  ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey.shade200),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoadingProfile
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // --------------------------------------------------
                  // HEADER PROFILE AVATAR
                  // --------------------------------------------------
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 38,
                          backgroundColor: primaryColor.withOpacity(0.12),
                          child: Icon(Icons.storefront_rounded, size: 40, color: primaryColor),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _shopNameController.text.isNotEmpty ? _shopNameController.text : 'My Shop',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email,
                          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // SHOP INFORMATION CARD
                  // --------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.store_rounded, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Shop Information',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        TextField(
                          controller: _shopNameController,
                          decoration: _buildInputDecoration('Shop Name', Icons.store_outlined),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ownerNameController,
                          decoration: _buildInputDecoration('Owner Name', Icons.person_outline),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _addressController,
                          decoration: _buildInputDecoration('Address', Icons.location_on_outlined),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _phoneController,
                          keyboardType: TextInputType.phone,
                          decoration: _buildInputDecoration('Phone Number', Icons.phone_outlined),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          enabled: false,
                          controller: TextEditingController(text: email),
                          decoration: _buildInputDecoration('Email Address', Icons.email_outlined),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: _isSavingProfile
                              ? const Center(child: CircularProgressIndicator())
                              : ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    elevation: 1,
                                  ),
                                  onPressed: _saveProfile,
                                  icon: const Icon(Icons.check_circle_outline_rounded, size: 20),
                                  label: const Text('Save Changes', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                                ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // --------------------------------------------------
                  // ACCOUNT SETTINGS CARD
                  // --------------------------------------------------
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.manage_accounts_rounded, color: primaryColor, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Account Settings',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Change Password
                        _buildActionButton(
                          icon: Icons.lock_outline_rounded,
                          title: 'Change Password',
                          color: Colors.grey.shade800,
                          backgroundColor: Colors.grey.shade100,
                          onTap: _showChangePasswordDialog,
                        ),

                        const SizedBox(height: 10),

                        // Logout
                        _buildActionButton(
                          icon: Icons.logout_rounded,
                          title: 'Logout',
                          color: Colors.orange.shade800,
                          backgroundColor: Colors.orange.shade50,
                          onTap: () async {
                            await FirebaseAuth.instance.signOut();
                            if (context.mounted) {
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(builder: (_) => const AuthGate()),
                                (route) => false,
                              );
                            }
                          },
                        ),

                        const SizedBox(height: 10),

                        // Delete Account
                        _buildActionButton(
                          icon: Icons.delete_forever_rounded,
                          title: 'Delete Account',
                          color: Colors.red.shade700,
                          backgroundColor: Colors.red.shade50,
                          onTap: _showDeleteAccountDialog,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }

  // Action Button Helper Widget
  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required Color color,
    required Color backgroundColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color),
              ),
              const Spacer(),
              Icon(Icons.arrow_forward_ios_rounded, color: color.withOpacity(0.6), size: 14),
            ],
          ),
        ),
      ),
    );
  }
}
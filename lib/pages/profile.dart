import 'dart:io';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/service/auth.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/service/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/widget/widget_support.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final Color _themeOrange = const Color(0xFFff5c30); // Define the theme color

  String? profile, name, email, userId;
  final ImagePicker _picker = ImagePicker();
  File? selectedImage;
  bool _isLoading = true;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// 🔹 Load user data from SharedPreferences and Firestore
  Future<void> _loadUserData() async {
    // Load all data from shared preferences first
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    userId = await SharedPreferenceHelper().getUserId();
    profile = await SharedPreferenceHelper().getUserProfile();

    // If profile is still missing from shared preferences, check Firestore
    if (userId != null && (profile == null || profile!.isEmpty)) {
      try {
        final doc = await FirebaseFirestore.instance.collection("user").doc(userId).get();
        if (doc.exists && doc.data()!["Profile"] != null) {
          final newProfileUrl = doc["Profile"] as String;
          if (newProfileUrl.isNotEmpty) {
            profile = newProfileUrl;
            // Sync the found URL back to SharedPreferences
            await SharedPreferenceHelper().saveUserProfile(profile!);
          }
        }
      } catch (e) {
        // Handle Firestore read error
        debugPrint("Error loading profile from Firestore: $e");
      }
    }

    setState(() => _isLoading = false);
  }

  /// 🔹 Pick and upload profile image (Cloudinary)
  Future<void> _getImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked == null) return;

    selectedImage = File(picked.path);
    setState(() => _isUploading = true);

    if (userId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("❌ User ID not found. Please log in again."),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isUploading = false);
      return;
    }

    try {
      final imageUrl = await CloudinaryService.uploadImage(selectedImage!);

      if (imageUrl == null || imageUrl.isEmpty) {
        throw Exception("Cloudinary upload failed: Returned null or empty URL.");
      }

      // 1. Save to Firestore (Database)
      await FirebaseFirestore.instance.collection("user").doc(userId).update({
        "Profile": imageUrl,
      });

      // 2. Update SharedPreferences (Local Cache)
      await SharedPreferenceHelper().saveUserProfile(imageUrl);

      // 3. Update UI state
      setState(() {
        profile = imageUrl;
        _isUploading = false;
        selectedImage = null; // Clear local file reference
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Profile picture updated successfully!"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      setState(() => _isUploading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("❌ Failed to upload image: ${e.toString()}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  /// 🔹 Log out user
  Future<void> _logout() async {
    try {
      await AuthMethods().signOut();
      await SharedPreferenceHelper().clearAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("✅ Logged out successfully!"),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to Login (or Onboard) and clear stack
      Navigator.pushNamedAndRemoveUntil(context, '/LogIn', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Logout failed: $e")));
    }
  }

  /// 🔹 Delete account with confirmation
  Future<void> _deleteAccount() async {
    try {
      // NOTE: Using a custom dialog instead of Flutter's default to match theme/style
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text("Delete Account?", style: AppWidget.semiBoldTextFeildStyle()),
          content: const Text(
            "This action cannot be undone. Are you sure you want to permanently delete your account?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text("Cancel", style: TextStyle(color: _themeOrange)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text("Delete", style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      if (userId != null) {
        await FirebaseFirestore.instance.collection("user").doc(userId).delete();
      }

      await AuthMethods().deleteUser();
      await SharedPreferenceHelper().clearAll();

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("🗑 Account deleted successfully"),
          backgroundColor: Colors.redAccent,
        ),
      );

      Navigator.pushNamedAndRemoveUntil(context, '/LogIn', (route) => false);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("❌ Error deleting account: $e")));
    }
  }

  /// 🔹 Helper widget for clean profile tile UI
  Widget _buildProfileTile({required IconData icon, required String label, required String value}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: _themeOrange),
        title: Text(
          label,
          style: AppWidget.LightTextFeildStyle().copyWith(fontSize: 14, color: Colors.grey[600]),
        ),
        subtitle: Text(
          value,
          style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 16),
        ),
      ),
    );
  }

  /// 🔹 Helper widget for actionable tiles
  Widget _buildActionTile({required IconData icon, required String label, VoidCallback? onTap, Color? color}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: color ?? _themeOrange),
        title: Text(
          label,
          style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 16, color: color ?? Colors.black),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(body: Center(child: CircularProgressIndicator(color: _themeOrange)));
    }

    return Scaffold(
      backgroundColor: Colors.grey[50], // Consistent light background
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- 1. Themed Header and Profile Picture ---
            Container(
              height: MediaQuery.of(context).size.height * 0.35, // Taller header
              width: MediaQuery.of(context).size.width,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_themeOrange, const Color(0xFFe74b1a)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(50), // Rounded bottom corners
                  bottomRight: Radius.circular(50),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Title
                  Padding(
                    padding: const EdgeInsets.only(top: 30.0),
                    child: Text(
                      "My Profile",
                      style: AppWidget.boldTextFeildStyle().copyWith(color: Colors.white, fontSize: 24),
                    ),
                  ),
                  const SizedBox(height: 15),

                  // Profile Picture
                  GestureDetector(
                    onTap: _getImage,
                    child: Stack(
                      children: [
                        // Profile Image/Placeholder
                        Material(
                          elevation: 10.0,
                          borderRadius: BorderRadius.circular(60),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(60),
                            child: (profile != null && profile!.isNotEmpty
                                ? Image.network(
                              profile!,
                              height: 120,
                              width: 120,
                              fit: BoxFit.cover,
                            )
                                : Container(
                              height: 120,
                              width: 120,
                              color: Colors.grey.shade300,
                              child: Icon(
                                Icons.person,
                                size: 70,
                                color: Colors.grey[600],
                              ),
                            )),
                          ),
                        ),
                        // Loading Indicator
                        if (_isUploading)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(60),
                              ),
                              child: const Center(
                                child: CircularProgressIndicator(color: Colors.white),
                              ),
                            ),
                          ),
                        // Edit Icon
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _themeOrange, width: 2),
                            ),
                            child: Icon(Icons.camera_alt, color: _themeOrange, size: 20),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Name Text
                  Text(
                    name ?? "User Name",
                    style: AppWidget.boldTextFeildStyle().copyWith(
                      color: Colors.white,
                      fontSize: 22.0,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30.0),

            // --- 2. Information Tiles ---
            _buildProfileTile(
              icon: Icons.badge_outlined,
              label: "Name",
              value: name ?? "Unknown",
            ),
            _buildProfileTile(
              icon: Icons.email_outlined,
              label: "Email Address",
              value: email ?? "N/A",
            ),

            const SizedBox(height: 30.0),

            // --- 3. Action Tiles ---
            _buildActionTile(
              icon: Icons.assignment_outlined,
              label: "Terms & Conditions",
              onTap: () {
                // Future: Implement navigation to T&C page
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Navigating to Terms & Conditions...")),
                );
              },
            ),

            _buildActionTile(
              icon: Icons.logout,
              label: "Logout",
              onTap: _logout,
            ),

            // --- 4. Dangerous Action (Delete) ---
            _buildActionTile(
              icon: Icons.delete_forever_outlined,
              label: "Delete Account",
              onTap: _deleteAccount,
              color: Colors.redAccent,
            ),

            const SizedBox(height: 50.0), // Padding for bottom nav bar
          ],
        ),
      ),
    );
  }
}
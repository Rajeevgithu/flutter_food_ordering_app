import 'dart:io';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/service/auth.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/service/cloudinary_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
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

  /// 🔹 Load user data from SharedPreferences
  Future<void> _loadUserData() async {
    profile = await SharedPreferenceHelper().getUserProfile();
    name = await SharedPreferenceHelper().getUserName();
    email = await SharedPreferenceHelper().getUserEmail();
    userId = await SharedPreferenceHelper().getUserId();

    // If profile is null, try to fetch from Firestore (for first-time login)
    if (profile == null || profile!.isEmpty) {
      final doc = await FirebaseFirestore.instance
          .collection("user")
          .doc(userId)
          .get();
      if (doc.exists && doc.data()!["Profile"] != null) {
        profile = doc["Profile"];
        await SharedPreferenceHelper().saveUserProfile(profile!);
      }
    }

    setState(() => _isLoading = false);
  }

  /// 🔹 Pick and upload profile image (Cloudinary)
  Future<void> _getImage() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    selectedImage = File(picked.path);
    setState(() => _isUploading = true);

    try {
      final imageUrl = await CloudinaryService.uploadImage(selectedImage!);

      if (imageUrl == null) throw Exception("Cloudinary returned null URL");

      // ✅ Save to Firestore
      await FirebaseFirestore.instance.collection("user").doc(userId).update({
        "Profile": imageUrl,
      });

      // ✅ Update SharedPreferences
      await SharedPreferenceHelper().saveUserProfile(imageUrl);

      setState(() {
        profile = imageUrl;
        _isUploading = false;
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
          content: Text("❌ Failed to upload image: $e"),
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
      final confirm = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Delete Account?"),
          content: const Text(
            "This action cannot be undone. Are you sure you want to permanently delete your account?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              child: const Text("Delete"),
            ),
          ],
        ),
      );

      if (confirm != true) return;

      await FirebaseFirestore.instance.collection("user").doc(userId).delete();
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

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  padding: const EdgeInsets.only(top: 45.0),
                  height: MediaQuery.of(context).size.height / 4.3,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.elliptical(
                        MediaQuery.of(context).size.width,
                        105.0,
                      ),
                    ),
                  ),
                ),
                Center(
                  child: Container(
                    margin: EdgeInsets.only(
                      top: MediaQuery.of(context).size.height / 6.5,
                    ),
                    child: Material(
                      elevation: 10.0,
                      borderRadius: BorderRadius.circular(60),
                      child: GestureDetector(
                        onTap: _getImage,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(60),
                          child: _isUploading
                              ? const SizedBox(
                                  height: 120,
                                  width: 120,
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                )
                              : (profile != null && profile!.isNotEmpty
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
                                        child: const Icon(
                                          Icons.camera_alt,
                                          size: 50,
                                          color: Colors.black54,
                                        ),
                                      )),
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 70.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        name ?? "User",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 23.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            _infoTile(Icons.person, "Name", name ?? "Unknown"),
            const SizedBox(height: 30.0),
            _infoTile(Icons.email, "Email", email ?? "N/A"),
            const SizedBox(height: 30.0),
            _simpleTile(Icons.description, "Terms & Conditions"),
            const SizedBox(height: 30.0),
            GestureDetector(
              onTap: _deleteAccount,
              child: _simpleTile(Icons.delete, "Delete Account"),
            ),
            const SizedBox(height: 30.0),
            GestureDetector(
              onTap: _logout,
              child: _simpleTile(Icons.logout, "Logout"),
            ),
            const SizedBox(height: 40.0),
          ],
        ),
      ),
    );
  }

  /// 🔹 Helper widgets for clean UI
  Widget _infoTile(IconData icon, String label, String value) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 2.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 20.0),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _simpleTile(IconData icon, String label) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Material(
        borderRadius: BorderRadius.circular(10),
        elevation: 2.0,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 15.0, horizontal: 10.0),
          child: Row(
            children: [
              Icon(icon, color: Colors.black),
              const SizedBox(width: 20.0),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:io';
import 'dart:convert'; // NEW: For converting image to text!
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'login_page.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String userEmail = "";
  String userName = "Loading...";
  String? profileImageUrl;
  bool _isUploadingPic = false;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // --- FETCH USER DATA ---
  Future<void> _fetchUserData() async {
    final user = _auth.currentUser;
    if (user != null) {
      setState(() => userEmail = user.email ?? "");
      try {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists) {
          setState(() {
            if (doc.data()!.containsKey('name')) userName = doc['name'];
            // This pulls the massive Base64 text string from the database!
            if (doc.data()!.containsKey('profileImageUrl')) {
              profileImageUrl = doc['profileImageUrl'];
            }
          });
        } else {
          String emailPrefix = userEmail.split('@')[0];
          setState(() {
            userName = emailPrefix[0].toUpperCase() + emailPrefix.substring(1);
          });
        }
      } catch (e) {
        debugPrint("Error fetching user: $e");
      }
    }
  }

  // --- THE CHEAT CODE: WEB-SAFE IMAGE UPLOAD ---
  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();

    // Pick the image (Shrunk to keep the database happy)
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 50,
    );

    if (pickedFile != null) {
      setState(() => _isUploadingPic = true);
      try {
        // THE FIX: readAsBytes() directly from the picked file!
        // This works on Chrome/Web! (The old dart:io File method crashes on web)
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        // Save the text directly to your existing Firestore database
        final user = _auth.currentUser;
        await _firestore.collection('users').doc(user!.uid).update({
          'profileImageUrl': base64String,
        });

        // Update the UI
        setState(() {
          profileImageUrl = base64String;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile photo updated succesfully!")),
          );
        }
      } catch (e) {
        if (mounted) {
          // Now it will tell us the exact error if it fails again!
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Upload failed: $e")));
        }
      } finally {
        if (mounted) setState(() => _isUploadingPic = false);
      }
    }
  }

  // --- EDIT NAME POPUP ---
  Future<void> _editNameDialog() async {
    TextEditingController nameController = TextEditingController(
      text: userName,
    );

    final newName = await showDialog<String>(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              "Edit Name",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF004D40),
              ),
            ),
            content: TextField(
              controller: nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                hintText: "Enter your name",
                filled: true,
                fillColor: Colors.grey.shade100,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed:
                    () => Navigator.pop(context, nameController.text.trim()),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00796B),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Save",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (newName != null && newName.isNotEmpty && newName != userName) {
      setState(() => userName = newName);
      if (_auth.currentUser != null) {
        await _firestore.collection('users').doc(_auth.currentUser!.uid).update(
          {'name': newName},
        );
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final bool? confirm = await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            title: const Text(
              "Log Out",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text("Are you sure you want to log out of ZENnie?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancel",
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  "Log Out",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );

    if (confirm == true) {
      await _auth.signOut();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
          (Route<dynamic> route) => false,
        );
      }
    }
  }

  Widget _buildActionTile(
    String title,
    IconData icon,
    VoidCallback onTap, {
    String? subtitle,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey.shade600),
      ),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle:
          subtitle != null
              ? Text(
                subtitle,
                style: TextStyle(color: Colors.teal.shade700, fontSize: 12),
              )
              : null,
      trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey.shade300),
      onTap: onTap,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFE0F4F1), Color(0xFFB5EADF), Color(0xFF8DE4D3)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(
              left: 24,
              right: 24,
              top: 40,
              bottom: 120,
            ),
            child: Column(
              children: [
                // --- WORKING PROFILE PHOTO UPLOAD (NO CLOUD STORAGE NEEDED) ---
                GestureDetector(
                  onTap: _isUploadingPic ? null : _pickAndUploadImage,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 56,
                          backgroundColor: const Color(0xFFF4FBF9),
                          // Decodes the text back into a beautiful image!
                          backgroundImage:
                              profileImageUrl != null &&
                                      profileImageUrl!.length > 100
                                  ? MemoryImage(base64Decode(profileImageUrl!))
                                  : null,
                          child:
                              _isUploadingPic
                                  ? const CircularProgressIndicator(
                                    color: Colors.teal,
                                  )
                                  : (profileImageUrl == null ||
                                          profileImageUrl!.length < 100
                                      ? const Icon(
                                        Icons.person_rounded,
                                        size: 56,
                                        color: Color(0xFF8DE4D3),
                                      )
                                      : null),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF00796B),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // --- EDITABLE NAME ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004D40),
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _editNameDialog,
                      child: const Icon(
                        Icons.edit_rounded,
                        color: Color(0xFF00796B),
                        size: 20,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  userEmail,
                  style: TextStyle(fontSize: 14, color: Colors.teal.shade900),
                ),

                const SizedBox(height: 48),

                Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // --- CLEAN PRIVACY DIALOG ---
                      _buildActionTile(
                        "Privacy & Security",
                        Icons.lock_outline_rounded,
                        () {
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  title: const Row(
                                    children: [
                                      Icon(
                                        Icons.shield_rounded,
                                        color: Color(0xFF00796B),
                                      ),
                                      SizedBox(width: 10),
                                      Text(
                                        "Privacy & Security",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ],
                                  ),
                                  content: const Text(
                                    "Your mental health data is strictly confidential. All mood logs, journal entries, and AI conversations are encrypted and securely stored in Firebase.",
                                    style: TextStyle(height: 1.5),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: const Text(
                                        "Understood",
                                        style: TextStyle(
                                          color: Color(0xFF00796B),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),

                      const Divider(height: 1, indent: 20, endIndent: 20),

                      // --- HELPDESK EMAIL LAUNCHER ---
                      _buildActionTile(
                        "Help & Support",
                        Icons.help_outline_rounded,
                        () async {
                          final Uri emailLaunchUri = Uri.parse(
                            'mailto:82832@siswa.unimas.my?subject=ZENnie%20App%20Support',
                          );
                          if (await canLaunchUrl(emailLaunchUri)) {
                            await launchUrl(emailLaunchUri);
                          } else {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    "Could not open the email app. Please email 82832@siswa.unimas.my directly.",
                                  ),
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // --- LOGOUT BUTTON ---
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () => _handleLogout(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.shade50,
                      foregroundColor: Colors.red.shade400,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: const Text(
                      "Log Out",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'dart:typed_data';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login.dart';
import 'bottomnav.dart'; 

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final supabase = Supabase.instance.client;
  final picker = ImagePicker();

  late final String userId;
  String? email;
  String? avatarUrl;
  String? imagePath;
  String? errorText;
  bool isLoading = true;
  bool isUploading = false;

  File? _profileImage;
  Uint8List? _webImage;

  final usernameController = TextEditingController();
  final emailController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final user = supabase.auth.currentUser;
    if (user != null) {
      userId = user.id;
      email = user.email;
      emailController.text = email ?? '';
      fetchProfile();
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const LoginPage()),
        );
      });
    }
  }

  Future<void> fetchProfile() async {
    try {
      final data = await supabase
          .from('profiles')
          .select('username, avatar_url, image_path')
          .eq('id', userId)
          .single();

      setState(() {
        usernameController.text = data['username'] ?? '';
        avatarUrl = data['avatar_url'];
        imagePath = data['image_path'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load profile: $e')),
      );
    }
  }

  Future<void> pickAndUploadImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    final fileExt = picked.name.split('.').last;
    final filePath = 'avatars/$userId/profile.$fileExt';

    setState(() => isUploading = true);

    try {
      if (kIsWeb) {
        _webImage = await picked.readAsBytes();
        await supabase.storage.from('avatars').uploadBinary(
              filePath,
              _webImage!,
              fileOptions: FileOptions(upsert: true),
            );
      } else {
        _profileImage = File(picked.path);
        await supabase.storage.from('avatars').upload(
              filePath,
              _profileImage!,
              fileOptions: FileOptions(upsert: true),
            );
      }

      final publicUrl =
          supabase.storage.from('avatars').getPublicUrl(filePath);

      setState(() {
        avatarUrl = publicUrl;
        imagePath = filePath;
      });

      await updateProfile();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Image upload failed: $e')),
      );
    } finally {
      setState(() => isUploading = false);
    }
  }

  Future<void> updateProfile() async {
    try {
      await supabase.from('profiles').update({
        'username': usernameController.text.trim(),
        'avatar_url': avatarUrl,
        'image_path': imagePath,
      }).eq('id', userId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update profile: $e')),
      );
    }
  }

  Future<void> logout() async {
    await supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginPage()),
      );
    }
  }

  void _showChangePasswordDialog() {
    final currentController = TextEditingController();
    final newController = TextEditingController();
    final confirmController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          title: const Text('Change Password'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current Password'),
              ),
              TextField(
                controller: newController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New Password'),
              ),
              TextField(
                controller: confirmController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm Password'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                _changePassword(
                  currentController.text,
                  newController.text,
                  confirmController.text,
                );
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _changePassword(
      String currentPassword, String newPassword, String confirmPassword) async {
    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('New passwords do not match')),
      );
      return;
    }

    try {
      final email = supabase.auth.currentUser?.email;
      if (email == null) throw Exception("User email not found");

      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: currentPassword,
      );

      if (response.user == null) {
        throw Exception("Re-authentication failed");
      }

      await supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Password update failed: $e')),
      );
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      bottomNavigationBar: CustomBottomNav(currentIndex: 3, userId: '', userEmail: '', selectedIndex: 4, onTap: (int) {  },),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFF4DFEF), Color(0xFFD3F3F5)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: isLoading
            ? const Center(child: CircularProgressIndicator(color: Colors.white))
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: IconButton(
                            icon: const Icon(Icons.logout, color: Colors.white),
                            onPressed: logout,
                          ),
                        ),
                        GestureDetector(
                          onTap: pickAndUploadImage,
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              CircleAvatar(
                                radius: 60,
                                backgroundImage: avatarUrl != null
                                    ? NetworkImage(avatarUrl!)
                                    : const AssetImage('assets/images/profile.png')
                                        as ImageProvider,
                              ),
                              if (isUploading)
                                const CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 4,
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildTextField(usernameController, 'Username'),
                        const SizedBox(height: 16),
                        _buildTextField(emailController, 'Email', readOnly: true),
                        const SizedBox(height: 16),
                        _buildTextField(
                          TextEditingController(text: '••••••••'),
                          'Password',
                          readOnly: true,
                          obscureText: true,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: updateProfile,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 32,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save Changes', style: TextStyle(fontSize: 16)),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _showChangePasswordDialog,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.teal,
                            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Change Password', style: TextStyle(fontSize: 16)),
                        ),
                        if (errorText != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label,
      {bool readOnly = false, bool obscureText = false}) {
    return TextField(
      controller: controller,
      readOnly: readOnly,
      obscureText: obscureText,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black),
        filled: true,
        fillColor: Colors.white.withOpacity(0.15),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.white60),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      style: const TextStyle(color: Colors.black),
    );
  }
}

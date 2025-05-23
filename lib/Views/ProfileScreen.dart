import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:homepage/models/person.dart';

class ProfileScreen extends StatefulWidget {
  final Person person;
  const ProfileScreen({super.key, required this.person});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  final SupabaseClient _supabase = Supabase.instance.client;

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() => _imageFile = File(pickedFile.path));
        await _uploadImageToSupabase();
      }
    } catch (e) {
      _showErrorSnackbar('An error occurred while selecting the image');
      debugPrint('Image picking error: $e');
    }
  }

  Future<void> _uploadImageToSupabase() async {
    if (_imageFile == null) return;

    setState(() => _isUploading = true);

    try {
      // Create unique filename to prevent conflicts
      final String fileExtension = path.extension(_imageFile!.path);
      final String fileName = '${widget.person.id}_${DateTime.now().millisecondsSinceEpoch}$fileExtension';
      
      // Upload to Supabase storage
      await _supabase.storage
          .from('avatars')
          .upload('public/$fileName', _imageFile!);

      // Get public URL
      final String imageUrl = _supabase.storage
          .from('avatars')
          .getPublicUrl('public/$fileName');

      // Update user record in database
      await _supabase
          .from('users')
          .update({'image': imageUrl})
          .eq('id', widget.person.id);

      // Update local state
      setState(() => widget.person.image = imageUrl);
      
      _showSuccessSnackbar('Image updated successfully');
    } on StorageException catch (e) {
      _showErrorSnackbar('Error storing image');
      debugPrint('Storage error: ${e.message}');
    } catch (e) {
      _showErrorSnackbar('An unexpected error occurred');
      debugPrint('Upload error: $e');
    } finally {
      if (mounted) {
        setState(() => _isUploading = false);
      }
    }
  }

  void _showImageSourceSelector() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Take a picture with the camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Selection from the gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showSuccessSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Profile', style: TextStyle(fontSize: 25)),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundImage: _getProfileImage(),
                  ),
                  Positioned(
                    bottom: -5,
                    right: -5,
                    child: Material(
                      shape: const CircleBorder(),
                      color: Colors.blue,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(25),
                        onTap: _isUploading ? null : _showImageSourceSelector,
                        child: Padding(
                          padding: const EdgeInsets.all(10),
                          child: _isUploading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.camera_alt, size: 20, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.person.name,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              widget.person.email ?? '',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 30),
            // Add additional profile fields here
          ],
        ),
      ),
    );
  }

  ImageProvider _getProfileImage() {
    if (widget.person.image != null && widget.person.image!.isNotEmpty) {
      return NetworkImage(widget.person.image!);
    }
    return const AssetImage('');
  }
}
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
  final _formKey = GlobalKey<FormState>();
  bool _isSeller = false; // Default is customer (false)
  bool _isSwitchingRole = false;

  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.person.name);
    _phoneController = TextEditingController(text: widget.person.phone ?? '');
    _passwordController = TextEditingController();
    // Initialize role from person if available, otherwise default to customer
    _isSeller = widget.person.role == 'seller';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  ImageProvider<Object>? _getProfileImage() {
  if (_imageFile != null) {
    return FileImage(_imageFile!);
  } else if (widget.person.image != null && widget.person.image!.isNotEmpty) {
    return NetworkImage(widget.person.image!);
  }
  return null;
}

  Future<String?> _uploadImage(File file) async {
  final fileExt = path.extension(file.path);
  final fileName = '${widget.person.id}_${DateTime.now().millisecondsSinceEpoch}$fileExt';
  final filePath = 'avatars/$fileName';

  try {
    final bytes = await file.readAsBytes();

    final response = await _supabase.storage
        .from('avatars') // اسم الباكت
        .uploadBinary(filePath, bytes, fileOptions: const FileOptions(
          upsert: true,
          contentType: 'image/jpeg',
        ));

    final publicUrl = _supabase.storage
        .from('avatars')
        .getPublicUrl(filePath);

    return publicUrl;
  } catch (e) {
    debugPrint('Upload failed: $e');
    return null;
  }
}


  Future<void> _showImageSourceSelector() async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (context) => SafeArea(
      child: Wrap(
        children: [
          ListTile(
            leading: const Icon(Icons.photo_library),
            title: const Text('Gallery'),
            onTap: () => Navigator.pop(context, ImageSource.gallery),
          ),
          ListTile(
            leading: const Icon(Icons.camera_alt),
            title: const Text('Camera'),
            onTap: () => Navigator.pop(context, ImageSource.camera),
          ),
        ],
      ),
    ),
  );

  if (source != null) {
    final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() => _isUploading = true);

      final file = File(pickedFile.path);
      final imageUrl = await _uploadImage(file);
      if (imageUrl != null) {
        await _supabase
            .from('users')
            .update({'avatar_url': imageUrl})
            .eq('id', widget.person.id);

        setState(() {
          _imageFile = file;
          widget.person.image = imageUrl;
        });
      }

      setState(() => _isUploading = false);
    }
  }
}

Future<void> _saveProfileChanges() async {
  if (!_formKey.currentState!.validate()) return;

  setState(() => _isUploading = true);

  final updates = <String, dynamic>{
    'name': _nameController.text.trim(),
    'phone': _phoneController.text.trim(),
  };

  if (_passwordController.text.isNotEmpty) {
    try {
      // تحديث كلمة المرور باستخدام Auth
      await _supabase.auth.updateUser(
        UserAttributes(password: _passwordController.text.trim()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update password: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isUploading = false);
      return;
    }
  }

  try {
    // تحديث بيانات المستخدم في جدول users
    await _supabase
        .from('users')
        .update(updates)
        .eq('id', widget.person.id);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Profile updated successfully'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Failed to update profile: ${e.toString()}'),
        backgroundColor: Colors.red,
      ),
    );
  }

  setState(() => _isUploading = false);
}



  Future<void> _switchRole(bool newValue) async {
    setState(() => _isSwitchingRole = true);
    try {
      // Update role in database
      await _supabase
          .from('users')
          .update({'role': newValue ? 'seller' : 'customer'})
          .eq('id', widget.person.id);

      // Logout user
      await _supabase.auth.signOut();
      
      // Redirect to login screen
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context, 
          '/login', 
          (route) => false
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to switch role: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSwitchingRole = false);
      }
    }
  }

  // ... [Keep all your existing methods unchanged] ...

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('My Profile',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            )),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.black54),
            onPressed: () async {
              await _supabase.auth.signOut();
              if (mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/login', (route) => false);
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Add the role switch at the top
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: ListTile(
                title: const Text('Seller Account'),
                subtitle: const Text('Switch to seller mode'),
                trailing: Switch(
                  value: _isSeller,
                  onChanged: _isSwitchingRole 
                      ? null 
                      : (value) async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Switch Role'),
                              content: Text(
                                  'Switch to ${value ? 'seller' : 'customer'} account? You will be logged out.'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Confirm'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            await _switchRole(value);
                          }
                        },
                  activeColor: Colors.blue,
                ),
              ),
            ),

            // Keep all your existing widgets below exactly as they were
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey[300]!,
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _getProfileImage(),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton.small(
                      backgroundColor: Colors.blue,
                      onPressed: _isUploading ? null : _showImageSourceSelector,
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
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Rest of your existing form widgets...
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Full Name',
                        prefixIcon: const Icon(Icons.person),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) =>
                          value!.isEmpty ? 'Please enter your name' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Phone Number',
                        prefixIcon: const Icon(Icons.phone),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: 'New Password',
                        prefixIcon: const Icon(Icons.lock),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _isUploading ? null : _saveProfileChanges,
                        child: _isUploading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              )
                            : const Text(
                                'Save Changes',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ... [Keep all your remaining existing methods unchanged] ...
}
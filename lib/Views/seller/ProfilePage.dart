import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as path;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'SellerScaffold.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});
  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  File? _imageFile;
  bool _isUploading = false;
  bool _isSwitchingRole = false;

  bool _isSeller = false;
  Map<String, dynamic>? _user;
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchUser();
  }

  Future<void> _fetchUser() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final data = await _supabase.from('users').select().eq('id', user.id).maybeSingle();
    if (data != null && mounted) {
      setState(() {
        _user = data;
        _nameController.text = data['name'] ?? '';
        _phoneController.text = data['phone'] ?? '';
        _isSeller = data['role'] == 'seller';
      });
    }
  }

  ImageProvider? _getAvatar() {
    if (_imageFile != null) return FileImage(_imageFile!);
    if (_user?['image'] != null && _user!['image'].isNotEmpty) {
      return NetworkImage(_user!['image']);
    }
    return null;
  }

  Future<void> _pickImage() async {
    final xfile = await _picker.pickImage(source: ImageSource.gallery);
    if (xfile == null) return;

    setState(() => _isUploading = true);

    final file = File(xfile.path);
    final fileName = '${_user!['id']}_${DateTime.now().millisecondsSinceEpoch}${path.extension(xfile.path)}';
    final filePath = 'avatars/$fileName';

    try {
      await _supabase.storage.from('avatars').uploadBinary(filePath, await file.readAsBytes());
      final url = _supabase.storage.from('avatars').getPublicUrl(filePath);

      await _supabase.from('users').update({'image': url}).eq('id', _user!['id']);
      setState(() {
        _imageFile = file;
        _user!['image'] = url;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile picture updated.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
    }

    setState(() => _isUploading = false);
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    final updates = {
      'name': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
    };

    try {
      if (_passwordController.text.isNotEmpty) {
        await _supabase.auth.updateUser(UserAttributes(password: _passwordController.text.trim()));
      }

      await _supabase.from('users').update(updates).eq('id', _user!['id']);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Profile updated successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to update: $e')),
      );
    }

    setState(() => _isUploading = false);
  }

  Future<void> _switchRole(bool seller) async {
    setState(() => _isSwitchingRole = true);

    try {
      await _supabase.from('users').update({'role': seller ? 'seller' : 'customer'}).eq('id', _user!['id']);
      await _supabase.auth.signOut();
      if (mounted) {
        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Role switch failed: $e')),
      );
    }

    setState(() => _isSwitchingRole = false);
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null) {
      return SellerScaffold(
        title: 'Profile',
        sellerName: '',
        sellerEmail: '',
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return SellerScaffold(
      title: 'Profile',
      sellerName: _user!['name'] ?? 'Seller',
      sellerEmail: _user!['email'] ?? 'email@domain.com',
      sellerImageUrl: _user!['image'],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[300]!, width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 58,
                      backgroundImage: _getAvatar(),
                      backgroundColor: Colors.grey[200],
                      child: _getAvatar() == null
                          ? const Icon(Icons.person, size: 50, color: Colors.grey)
                          : null,
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.grey[300]!),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: _isUploading ? null : _pickImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _isSeller ? 'Seller Account' : 'Customer Account',
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                  Switch(
                    value: _isSeller,
                    onChanged: _isSwitchingRole
                        ? null
                        : (val) async {
                            final confirmed = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text('Switch Role'),
                                content: Text(
                                  'Switch to ${val ? 'Seller' : 'Customer'} account? You will be logged out.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('CANCEL', style: TextStyle(color: Colors.black)),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    child: const Text('CONFIRM', style: TextStyle(color: Colors.black)),
                                  ),
                                ],
                              ),
                            );
                            if (confirmed == true) _switchRole(val);
                          },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            Text('PROFILE DETAILS',
                style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 1.2)),
            const SizedBox(height: 16),
            Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _nameController,
                    decoration: _inputDecoration('Full Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: _inputDecoration('Phone Number'),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    decoration: _inputDecoration('New Password'),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isUploading ? null : _saveChanges,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isUploading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'SAVE CHANGES',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

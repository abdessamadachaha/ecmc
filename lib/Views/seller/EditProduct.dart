import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/uuid.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditProductScreen extends StatefulWidget {
  final String productId;
  const EditProductScreen({required this.productId, Key? key}) : super(key: key);

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  // ▼▼▼ KEEP ALL YOUR EXISTING CODE ▼▼▼
  final _supabase = Supabase.instance.client;
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();

  String? _condition;
  String? _imageUrl;
  bool _isUploading = false;

  List<Map<String, dynamic>> _categories = [];
  Map<String, int> _categoryMap = {};
  String? _selectedCategoryName;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _initAll();
  }

  Future<void> _initAll() async {
    try {
      await Future.wait([
        _loadCategories(),
        _loadProduct(),
      ]);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to load data: $e")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loadCategories() async {
    final response = await _supabase.from('category').select('id,name');
    final list = List<Map<String, dynamic>>.from(response);
    _categoryMap = {
      for (final c in list) c['name'] as String: c['id'] as int,
    };
    _categories = list;
  }

  Future<void> _loadProduct() async {
    final data = await _supabase
        .from('product')
        .select()
        .eq('id', widget.productId)
        .maybeSingle();

    if (data != null) {
      _nameController.text = data['name'] ?? '';
      _descriptionController.text = data['description'] ?? '';
      _priceController.text = data['price'].toString();
      _quantityController.text = data['quantity'].toString();
      _condition = data['condition'];
      _imageUrl = data['image'];
      final catId = data['id_category'] as int;
      _selectedCategoryName = _categoryMap.entries
          .firstWhere((e) => e.value == catId, orElse: () => const MapEntry('', 0))
          .key;
    }
  }

  Future<void> _pickImageAndUpload() async {
    final picker = ImagePicker();
    final xfile = await picker.pickImage(source: ImageSource.gallery);

    if (xfile == null) return;

    setState(() => _isUploading = true);

    try {
      final fileBytes = await xfile.readAsBytes();
      final ext = p.extension(xfile.path);
      final fileName = '${const Uuid().v4()}$ext';
      final path = 'products/$fileName';

      await _supabase.storage
          .from('product')
          .uploadBinary(path, fileBytes);

      final url = _supabase.storage
          .from('product')
          .getPublicUrl(path);

      setState(() => _imageUrl = url);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Upload failed: ${e.toString()}')),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final categoryId = _categoryMap[_selectedCategoryName];
    if (categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select a valid category")),
      );
      return;
    }

    try {
      await _supabase.from('product').update({
        'name': _nameController.text,
        'description': _descriptionController.text,
        'price': double.parse(_priceController.text),
        'quantity': int.parse(_quantityController.text),
        'condition': _condition,
        'image': _imageUrl,
        'id_category': categoryId,
      }).eq('id', widget.productId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Product updated successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }
  // ▲▲▲ KEEP ALL YOUR EXISTING CODE ▲▲▲

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Edit Product',
              style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          elevation: 0,
          centerTitle: true,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Product',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ▼▼▼ ONLY UI CHANGES START HERE ▼▼▼
              // Image Section
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickImageAndUpload,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[300]!,
                            width: 1.5,
                            style: BorderStyle.solid,
                          ),
                        ),
                        child: _imageUrl == null
                            ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo,
                                size: 40, color: Colors.grey[400]),
                            const SizedBox(height: 8),
                            Text(
                              'Add Product Image',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        )
                            : ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: Stack(
                            children: [
                              Image.network(
                                _imageUrl!,
                                width: 150,
                                height: 150,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, progress) {
                                  return progress == null
                                      ? child
                                      : Container(color: Colors.grey[100]);
                                },
                                errorBuilder: (_, __, ___) => Container(
                                  color: Colors.grey[100],
                                  child: const Icon(Icons.error),
                                ),
                              ),
                              if (_isUploading)
                                Container(
                                  color: Colors.black54,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: _pickImageAndUpload,
                      child: Text(
                        _imageUrl == null ? 'Upload Image' : 'Change Image',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Product Details
              const Text(
                'Product Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Product Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                  contentPadding: const EdgeInsets.all(14),
                ),
                maxLines: 3,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 16),

              // Category & Condition
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      isExpanded: true,
                      value: _selectedCategoryName,
                      items: _categories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat['name'],
                          child: Text(cat['name']),
                        );
                      }).toList(),
                      onChanged: (v) => setState(() => _selectedCategoryName = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: InputDecoration(
                        labelText: 'Condition',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      value: _condition,
                      items: ['New', 'Used - Excellent', 'Used - Good']
                          .map((c) => DropdownMenuItem(
                        value: c,
                        child: Text(c),
                      ))
                          .toList(),
                      onChanged: (v) => setState(() => _condition = v),
                      validator: (v) => v == null ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Price & Quantity
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceController,
                      decoration: InputDecoration(
                        labelText: 'Price',
                        prefixText: '\MAD ',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _quantityController,
                      decoration: InputDecoration(
                        labelText: 'Quantity',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: Colors.grey),
                        ),
                        contentPadding: const EdgeInsets.all(14),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Save Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'SAVE CHANGES',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              // ▲▲▲ ONLY UI CHANGES END HERE ▲▲▲
            ],
          ),
        ),
      ),
    );
  }
}
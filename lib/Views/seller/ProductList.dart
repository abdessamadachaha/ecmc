import 'package:flutter/material.dart';
import 'package:homepage/Views/seller/addProdact.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'EditProduct.dart';
import 'SellerScaffold.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  // ▼▼▼ KEEP ALL YOUR EXISTING CODE ▼▼▼
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _filteredProducts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _products.where((product) {
        final name = product['name'].toString().toLowerCase();
        return name.contains(query);
      }).toList();
    });
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not logged in")),
        );
        return;
      }

      final raw = await _supabase
          .from('product')
          .select(r'''
            id,
            name,
            price,
            image,
            condition,
            quantity,
            category!product_id_category_fkey (
              name
            )
          ''')
          .eq('id_seller', userId);

      final list = List<Map<String, dynamic>>.from(raw as List);
      setState(() {
        _products = list;
        _filteredProducts = list;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading products: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _deleteProduct(String productId) async {
    try {
      await _supabase.from('favorite').delete().eq('product_id', productId);
      await _supabase.from('product').delete().eq('id', productId);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Product and related favorites deleted')),
      );
      _loadProducts();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Delete failed: $e')),
      );
    }
  }
  // ▲▲▲ KEEP ALL YOUR EXISTING CODE ▲▲▲

  @override
  Widget build(BuildContext context) {

    return SellerScaffold(


      title: 'Product Inventory',
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.black,
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddProductScreen()),
          );
          _loadProducts();
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Column(
        children: [
          // ▼▼▼ ONLY UI CHANGES START HERE ▼▼▼
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(vertical: 15),
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inventory_2_outlined,
                      size: 60, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  const Text(
                    'No products found',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(bottom: 20),
              itemCount: _filteredProducts.length,
              itemBuilder: (context, i) {
                final p = _filteredProducts[i];
                final imageUrl = (p['image'] as String?)?.trim();
                final cat = p['category'] as Map<String, dynamic>?;
                final categoryName = (cat?['name'] as String?) ?? '—';

                return Container(
                  margin: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[100],
                        child: imageUrl != null && imageUrl.isNotEmpty
                            ? Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                          const Icon(Icons.broken_image),
                        )
                            : const Icon(Icons.image),
                      ),
                    ),
                    title: Text(
                      p['name'] as String,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        Text(
                          '${p['price']} \$ • Qty: ${p['quantity']}',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600]),
                        ),
                        Text(
                          'Category: $categoryName',
                          style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit,
                              color: Colors.blue),
                          onPressed: () async {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => EditProductScreen(
                                    productId: p['id'] as String),
                              ),
                            );
                            _loadProducts();
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete,
                              color: Colors.red),
                          onPressed: () =>
                              _deleteProduct(p['id'] as String),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          // ▲▲▲ ONLY UI CHANGES END HERE ▲▲▲
        ],
      ),
    );
  }
}
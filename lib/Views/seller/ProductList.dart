import 'package:flutter/material.dart';
import 'package:homepage/Views/seller/addProdact.dart';
import 'package:homepage/Views/seller/editProduct.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'SellerScaffold.dart'; // ✅ Make sure the path is correct

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({Key? key}) : super(key: key);

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[100],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.shopping_bag_outlined,
                                size: 64, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No products found',
                                style: TextStyle(fontSize: 20, color: Colors.grey[600])),
                            const SizedBox(height: 8),
                            Text('Tap the + button to add your first product',
                                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, i) {
                          final p = _filteredProducts[i];
                          final imageUrl = (p['image'] as String?)?.trim();
                          final cat = p['category'] as Map<String, dynamic>?;
                          final categoryName = (cat?['name'] as String?) ?? '—';

                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => EditProductScreen(
                                        productId: p['id'] as String),
                                  ),
                                );
                                _loadProducts();
                              },
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? Image.network(
                                              imageUrl,
                                              width: 80,
                                              height: 80,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) => Container(
                                                width: 80,
                                                height: 80,
                                                color: Colors.grey[200],
                                                child: const Icon(Icons.broken_image, color: Colors.grey),
                                              ),
                                            )
                                          : Container(
                                              width: 80,
                                              height: 80,
                                              color: Colors.grey[200],
                                              child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                            ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p['name'] as String,
                                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 6),
                                          Row(
                                            children: [
                                              _buildDetailChip('${p['price']} \$', Colors.grey[200]!),
                                              const SizedBox(width: 6),
                                              _buildDetailChip('Qty: ${p['quantity']}', Colors.grey[200]!),
                                            ],
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            'Category: $categoryName',
                                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                                          ),
                                          Text(
                                            'Condition: ${p['condition']}',
                                            style: const TextStyle(fontSize: 13, color: Colors.black54),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      children: [
                                        IconButton(
                                          icon: const Icon(Icons.edit, color: Colors.blue),
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
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _deleteProduct(p['id'] as String),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailChip(String text, Color backgroundColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

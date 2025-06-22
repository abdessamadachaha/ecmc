import 'package:flutter/material.dart';
import 'package:homepage/Views/DetailsScreen.dart';
import 'package:homepage/Views/ProfileScreen.dart';
import 'package:homepage/models/person.dart';
import 'package:homepage/models/product.dart';
import 'package:homepage/providers/favorite_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CategoryPage extends StatefulWidget {
  final Person person;
  const CategoryPage({super.key, required this.person});

  @override
  State<CategoryPage> createState() => _CategoryPageState();
}

class _CategoryPageState extends State<CategoryPage> {
  final List<String> categories = [
    'All',
    'Clothes',
    'Food',
    'Electronics',
    'School',
  ];

  final Map<String, int> categoryMap = {
    'Clothes': 4,
    'Food': 3,
    'Electronics': 2,
    'School': 1,
  };

  int selectedCategoryIndex = 0;
  String searchQuery = '';

  Future<List<dynamic>> fetchProducts() async {
    final supabase = Supabase.instance.client;
    final currentUserId = supabase.auth.currentUser?.id;
    var query = supabase.from('product').select();

    // Exclude products created by the current user
    if (currentUserId != null) {
      query = query.neq('id_seller', currentUserId);
    }

    if (selectedCategoryIndex != 0) {
      final categoryName = categories[selectedCategoryIndex];
      final categoryId = categoryMap[categoryName];
      if (categoryId != null) {
        query = query.eq('id_category', categoryId);
      }
    }

    if (searchQuery.isNotEmpty) {
      query = query.ilike('name', '%$searchQuery%');
    }

    return await query;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello,',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        widget.person.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ProfileScreen(person: widget.person),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: widget.person.image != null
                          ? NetworkImage(widget.person.image!)
                          : const AssetImage('assets/default_avatar.png') as ImageProvider,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              TextField(
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: 'Search products...',
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
                onChanged: (value) => setState(() => searchQuery = value),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: categories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) => _buildCategoryChip(index, categories[index]),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: FutureBuilder<List<dynamic>>(
                  future: fetchProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      );
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text('Error loading products', style: TextStyle(color: Colors.red[400])),
                      );
                    }
                    final products = snapshot.data ?? [];
                    if (products.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off, size: 60, color: Colors.grey[400]),
                            const SizedBox(height: 16),
                            Text('No products found', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                          ],
                        ),
                      );
                    }
                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.75,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) => _buildProductCard(products[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryChip(int index, String name) {
    final isSelected = index == selectedCategoryIndex;
    return GestureDetector(
      onTap: () => setState(() => selectedCategoryIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? Colors.black : Colors.grey[300]!),
        ),
        child: Text(
          name,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Detailsscreen(
            product: Product(
              id: product['id'],
              nameOfProduct: product['name'],
              image: product['image'],
              price: product['price'],
              description: product['description'],
              condition: product['condition'],
              quantity: product['quantity'],
              idSeller: product['id_seller'],
            ),
          ),
        ),
      );
    },
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Container(
              height: 120,
              width: double.infinity,
              color: Colors.grey[100],
              child: product['image'] != null 
                  ? Image.network(
                      product['image'],
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(Icons.image_not_supported, color: Colors.grey[400]),
                      ),
                    )
                  : Center(
                      child: Icon(Icons.image, color: Colors.grey[400]),
                    ),
            ),
          ),
          // Product Info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Title
                Text(
                  product['name'] ?? 'No Name',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                // Price with orange accent
                Text(
                  '${product['price']} MAD',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFF8C42), // Deep orange color
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

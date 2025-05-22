import 'package:flutter/material.dart';
import 'package:homepage/Views/DetailsScreen.dart';
import 'package:homepage/models/person.dart';
import 'package:homepage/models/product.dart';
import 'package:homepage/providers/favorite_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PageCategory extends StatefulWidget {
  @override
  State<PageCategory> createState() => _PageCategoryState();
}

class _PageCategoryState extends State<PageCategory> {
 
  final List<String> categories = [
    'All Products',
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

  int isSelected = 0;
  String searchQuery = '';

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

  }

  

  Future<List<dynamic>> fetchProducts() async {
    final supabase = Supabase.instance.client;
    var query = supabase.from('product').select();

    if (isSelected != 0) {
      final categoryName = categories[isSelected];
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
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'customer!.name',
                    style: TextStyle(
                      fontSize: 18,
                      fontStyle: FontStyle.normal,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  CircleAvatar(radius: 20, backgroundImage: NetworkImage('')),
                ],
              ),
            ),

            SizedBox(height: 30),
            TextField(
              decoration: InputDecoration(
                hintText: 'Search about Product..',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: Colors.black),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(28),
                  borderSide: BorderSide(color: Colors.black, width: 2.0),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
            const SizedBox(height: 10),

            SizedBox(
              height: 45,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  return _buildProductCategory(index, categories[index]);
                },
              ),
            ),
            const SizedBox(height: 10),

            Expanded(
              child: FutureBuilder<List<dynamic>>(
                future: fetchProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  }

                  final products = snapshot.data ?? [];
                  if (products.isEmpty) {
                    return const Center(
                      child: Text(
                        'No matching products',
                        style: TextStyle(
                          fontSize: 18,
                          color: Color.fromARGB(255, 255, 0, 0),
                        ),
                      ),
                    );
                  }

                  return GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          mainAxisExtent: 300,
                          crossAxisCount: 2,
                          childAspectRatio: 0.8,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                        ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return Padding(
                        padding: const EdgeInsets.only(top: 12.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => Detailsscreen(
                                      product: Product(
                                        nameOfProduct: product['name'],
                                        image: product['image'],
                                        price: product['price'],
                                        description: product['description'],
                                        condition: product['condition'],
                                        idSeller: product['id_seller'],
                                      ),
                                    ),
                              ),
                            );
                          },

                          child: Container(
                            color: Colors.white,
                            child: Column(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8.0),
                                    child: Image.network(
                                      product['image'] ?? '',
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      errorBuilder:
                                          (_, __, ___) =>
                                              const Icon(Icons.broken_image),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    top: 10.0,
                                    left: 8.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      product['name'] ?? '',
                                      style: const TextStyle(fontSize: 15.0),
                                    ),
                                  ),
                                ),

                                Padding(
                                  padding: const EdgeInsets.only(
                                    left: 8.0,
                                    top: 4.0,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      '${product['price']} MAD',
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCategory(int index, String name) => GestureDetector(
    onTap: () {
      setState(() {
        isSelected = index;
      });
    },
    child: Container(
      width: 100,
      margin: const EdgeInsets.only(right: 10, top: 5),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected == index ? Colors.black : Color(0xfff5f6fa),
        borderRadius: BorderRadius.circular(17.0),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: isSelected == index ? Colors.white : Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );
}
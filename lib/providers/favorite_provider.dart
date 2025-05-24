import 'package:flutter/material.dart';
import 'package:homepage/models/product.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Product> _favorites = [];
  List<Product> get favorites => _favorites;

  final SupabaseClient _supabase = Supabase.instance.client;
  String? get customerId => _supabase.auth.currentUser?.id;

  // Add this initialization method
  Future<void> initialize() async {
    if (customerId != null) {
      await fetchFavorites();
    }
    _supabase.auth.onAuthStateChange.listen((event) async {
      if (customerId != null) {
        await fetchFavorites();
      } else {
        _favorites.clear();
        notifyListeners();
      }
    });
  }

  Future<void> fetchFavorites() async {
    try {
      final response = await _supabase
          .from('favorite')
          .select('''
            product_id,
            product:product_id (*)
          ''')
          .eq('customer_id', customerId!);

      _favorites.clear();
      
      for (final item in response) {
      if (item['product'] != null) {
        final productData = item['product'] as Map<String, dynamic>;
        final product = Product(
          id: productData['id'],
          nameOfProduct: productData['name'],
          description: productData['description'],
          price: productData['price'],
          image: productData['image'],
          quantity: productData['quantity'],
          condition: productData['condition'],
          idSeller: productData['id_seller']
          // other fields...
        );
        _favorites.add(product);
      }
    }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching favorites: $e');
    }
  }

  void toggleProduct(Product product) async {
    if (isExist(product)) {
      await removeFromDatabase(product);
      _favorites.removeWhere((p) => p.id == product.id);
    } else {
      await addToDatabase(product);
      _favorites.add(product);
    }
    notifyListeners();
  }

  bool isExist(Product product) {
    return _favorites.any((p) => p.id == product.id);
  }

  Future<void> addToDatabase(Product product) async {
    await _supabase.from('favorite').insert({
      'customer_id': customerId,
      'product_id': product.id,
    });
  }

  Future<void> removeFromDatabase(Product product) async {
    await _supabase.from('favorite').delete().match({
      'customer_id': customerId!,
      'product_id': product.id,
    });
  }

  static FavoriteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}
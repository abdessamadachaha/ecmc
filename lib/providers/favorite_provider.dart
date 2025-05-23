import 'package:flutter/material.dart';
import 'package:homepage/models/product.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class FavoriteProvider extends ChangeNotifier {
  final List<Product> _favorites = [];
  List<Product> get favorites => _favorites;

  final SupabaseClient _supabase = Supabase.instance.client;
  final String customerId = Supabase.instance.client.auth.currentUser!.id;

  void toggleProduct(Product product) async {
    if (isExist(product)) {
      await removeFromDatabase(product);
      _favorites.remove(product);
    } else {
      await addToDatabase(product);
      _favorites.add(product);
    }
    notifyListeners();
  }

  bool isExist(Product product) {
    return _favorites.any((p) => p.id == product.id); // Adjust if you have unique ID
  }

  Future<void> addToDatabase(Product product) async {
    await _supabase.from('favorite').insert({
      'customer_id': customerId,
      'product_id': product.id,
    });
  }

  Future<void> removeFromDatabase(Product product) async {
    await _supabase.from('favorite').delete().match({
      'customer_id': customerId,
      'product_id': product.id,
    });
  }

  static FavoriteProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<FavoriteProvider>(context, listen: listen);
  }
}

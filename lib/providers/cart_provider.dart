import 'package:flutter/material.dart';
import 'package:homepage/models/CartItem.dart';
import 'package:homepage/models/product.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartProvider extends ChangeNotifier {
  final List<Cartitem> _cart = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  String? _cartId;
  bool _isLoading = false;
  bool _isInitialized = false;

  List<Cartitem> get cart => _cart;
  bool get isLoading => _isLoading;
  String? get userId => _supabase.auth.currentUser?.id;
  bool get isInitialized => _isInitialized;

  Future<void> initialize() async {
    if (_isInitialized) return;
    
    // Handle auth state changes
    _supabase.auth.onAuthStateChange.listen((event) async {
      if (userId != null) {
        await _loadCart();
      } else {
        _clearCart();
      }
    });

    if (userId != null) {
      await _loadCart();
    }
    _isInitialized = true;
  }

  Future<void> _loadCart() async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get or create cart
      final cartResponse = await _supabase
          .from('cart')
          .select()
          .eq('user_id', userId!)
          .maybeSingle();

      _cartId = cartResponse?['id'] ?? (await _supabase
          .from('cart')
          .insert({'user_id': userId!})
          .select()
          .single())['id'];

      // Load cart items with product details
      final itemsResponse = await _supabase
          .from('cart_item')
          .select('product:product_id(*), quantity')
          .eq('cart_id', _cartId!);

      _cart.clear();
      for (final item in itemsResponse) {
        if (item['product'] != null) {
          final productData = item['product'] as Map<String, dynamic>;
          _cart.add(Cartitem(
            product: Product(
              id: productData['id']?.toString() ?? '',
              nameOfProduct: productData['name']?.toString() ?? '',
              description: productData['description']?.toString() ?? '',
              price: productData['price'] ?? 0.0,
              image: productData['image']?.toString() ?? '',
              quantity: (productData['quantity'] as num?)?.toInt() ?? 0,
              condition: productData['condition']?.toString() ?? '',
              idSeller: productData['id_seller']?.toString() ?? '',
            ),
            quantity: (item['quantity'] as num?)?.toInt() ?? 1,
          ));
        }
      }
    } catch (e) {
      debugPrint('Error loading cart: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _clearCart() {
    _cart.clear();
    _cartId = null;
    notifyListeners();
  }

  Future<void> addToCart(Cartitem cartitem) async {
    if (userId == null) throw Exception('User not authenticated');
    if (_cartId == null) await initialize();

    try {
      final existingIndex = _cart.indexWhere((e) => e.product.id == cartitem.product.id);
      
      if (existingIndex >= 0) {
        _cart[existingIndex].quantity += cartitem.quantity;
        await _updateCartItem(_cart[existingIndex]);
      } else {
        _cart.add(cartitem);
        await _addCartItem(cartitem);
      }
      notifyListeners();
    } catch (e) {
      debugPrint('Error adding to cart: $e');
      rethrow;
    }
  }

  Future<void> _addCartItem(Cartitem item) async {
    await _supabase.from('cart_item').insert({
      'cart_id': _cartId!,
      'product_id': item.product.id,
      'quantity': item.quantity,
    });
  }

  Future<void> _updateCartItem(Cartitem item) async {
    await _supabase.from('cart_item')
      .update({'quantity': item.quantity})
      .match({
        'cart_id': _cartId!,
        'product_id': item.product.id,
      });
  }

  Future<void> removeFromCart(Cartitem cartitem) async {
    if (_cartId == null) return;
    
    try {
      await _supabase.from('cart_item').delete().match({
        'cart_id': _cartId!,
        'product_id': cartitem.product.id,
      });
      _cart.removeWhere((item) => item.product.id == cartitem.product.id);
      notifyListeners();
    } catch (e) {
      debugPrint('Error removing from cart: $e');
      rethrow;
    }
  }

  Future<void> updateQuantity(int index, int newQuantity) async {
    if (index >= _cart.length || _cartId == null || newQuantity < 1) return;
    
    try {
      _cart[index].quantity = newQuantity;
      await _updateCartItem(_cart[index]);
      notifyListeners();
    } catch (e) {
      debugPrint('Error updating quantity: $e');
      rethrow;
    }
  }

  Future<void> clearCart() async {
    if (_cartId == null) return;
    
    try {
      await _supabase.from('cart_item').delete().eq('cart_id', _cartId!);
      _cart.clear();
      notifyListeners();
    } catch (e) {
      debugPrint('Error clearing cart: $e');
      rethrow;
    }
  }

  static CartProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<CartProvider>(context, listen: listen);
  }
}
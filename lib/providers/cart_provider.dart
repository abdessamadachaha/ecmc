import 'package:flutter/material.dart';
import 'package:homepage/models/CartItem.dart';
import 'package:homepage/models/product.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CartProvider extends ChangeNotifier {
  final List<Cartitem> _cart = [];
  final SupabaseClient _supabase = Supabase.instance.client;
  final String userId = Supabase.instance.client.auth.currentUser!.id;

  List<Cartitem> get cart => _cart;

  Future<void> addToCart(Cartitem cartitem) async {
    final cartResponse = await _supabase
        .from('cart')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    String cartId;

    if (cartResponse == null) {
      final newCart = await _supabase.from('cart').insert({'user_id': userId}).select().single();
      cartId = newCart['id'];
    } else {
      cartId = cartResponse['id'];
    }

    // تحقق إذا كان المنتج موجود في السلة
    final exists = _cart.any((e) => e.product.id == cartitem.product.id);
    if (exists) {
      final existing = _cart.firstWhere((e) => e.product.id == cartitem.product.id);
      existing.quantity++;
      await _supabase
          .from('cart_item')
          .update({'quantity': existing.quantity})
          .match({
            'cart_id': cartId,
            'product_id': existing.product.id,
          });
    } else {
      _cart.add(cartitem);
      await _supabase.from('cart_item').insert({
        'cart_id': cartId,
        'product_id': cartitem.product.id,
        'quantity': cartitem.quantity,
      });
    }

    notifyListeners();
  }
  Future<void> removeFromCart(Cartitem cartitem) async {
    final productId = cartitem.product.id;

    final cart = await _supabase
        .from('cart')
        .select()
        .eq('user_id', userId)
        .maybeSingle();

    if (cart != null) {
      await _supabase.from('cart_item').delete().match({
        'cart_id': cart['id'],
        'product_id': productId,
      });
    }

    _cart.remove(cartitem);

    notifyListeners();
  }


  Future<void> incrementQuantity(int index) async {
    final item = _cart[index];
    item.quantity++;
    await _updateQuantity(item);
    notifyListeners();
  }

  Future<void> decrementQuantity(int index) async {
    final item = _cart[index];
    if (item.quantity > 1) {
      item.quantity--;
      await _updateQuantity(item);
      notifyListeners();
    }
  }

  Future<void> _updateQuantity(Cartitem item) async {
    final cart = await _supabase.from('cart').select().eq('user_id', userId).maybeSingle();
    if (cart != null) {
      await _supabase.from('cart_item').update({
        'quantity': item.quantity,
      }).match({
        'cart_id': cart['id'],
        'product_id': item.product.id,
      });
    }
  }

  static CartProvider of(BuildContext context, {bool listen = true}) {
    return Provider.of<CartProvider>(context, listen: listen);
  }
}

import 'package:flutter/material.dart';
import 'package:homepage/models/CartItem.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderProvider extends ChangeNotifier {
  final SupabaseClient _supabase = Supabase.instance.client;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> placeOrder(String customerId, String cartId, List<Cartitem> items) async {
  _isLoading = true;
  notifyListeners();

  try {
    final totalPrice = items.fold<double>(
      0.0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );


    final orderResponse = await _supabase.from('orders').insert({
      'customer_id': customerId,
      'cart_id': cartId,
      'total_price': totalPrice,
      'created_at': DateTime.now().toIso8601String(), 
    }).select().single();

    final orderId = orderResponse['id'];

    for (final item in items) {
      await _supabase.from('order_item').insert({
        'order_id': orderId,
        'seller_id':item.product.idSeller,
        'product_id': item.product.id,
        'quantity': item.quantity,
        'unit_price': item.product.price,
      });
    }

    debugPrint("✅ Order placed successfully.");
  } on PostgrestException catch (e) {
    debugPrint("Postgrest Error: ${e.message}");
    rethrow;
  } catch (e) {
    debugPrint("Unexpected error: $e");
    rethrow;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}

}

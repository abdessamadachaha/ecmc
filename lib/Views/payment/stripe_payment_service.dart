import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:http/http.dart' as http;
import '../../models/CartItem.dart';
import '../../config/constants.dart';

class StripePaymentService {
  static Future<void> payWithCard({
    required BuildContext context,
    required double amount,
    required List<Cartitem> cartItems,
    required String customerId,
    required VoidCallback onSuccess,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$supabaseFunctionUrl/create-payment'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"amount": amount}),
      );

      final data = jsonDecode(response.body);
      final clientSecret = data['clientSecret'];

      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Qality Store',
        ),
      );

      await Stripe.instance.presentPaymentSheet();

      await _createOrder(customerId, cartItems, amount);

      onSuccess();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Paiement échoué : $e")),
      );
    }
  }

  static Future<void> _createOrder(
      String customerId, List<Cartitem> cartItems, double totalAmount) async {
    final orderResponse = await http.post(
      Uri.parse('$supabaseRestUrl/orders'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "customer_id": customerId,
        "total_price": totalAmount,
        "created_at": DateTime.now().toIso8601String(),
      }),
    );

    final orderId = jsonDecode(orderResponse.body)['id'];

    for (var item in cartItems) {
      await http.post(
        Uri.parse('$supabaseRestUrl/order_item'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "product_id": item.product.id,
          "quantity": item.quantity,
          "unit_price": item.product.price,
          "seller_id": item.product.idSeller,
          "order_id": orderId,
        }),
      );
    }
  }
}

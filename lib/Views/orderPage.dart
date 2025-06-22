import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:homepage/providers/cart_provider.dart';
import 'package:homepage/providers/order_provider.dart';
import 'package:homepage/services/stripe_service.dart';
import 'package:provider/provider.dart';

class OrderPage extends StatelessWidget {
  const OrderPage({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = CartProvider.of(context);
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: const Text('Confirm Order'), centerTitle: true),
      body:
          cartProvider.cart.isEmpty
              ? const Center(child: Text('🛒 The basket is empty'))
              : Column(
                children: [
                  Expanded(
                    child: ListView.builder(
                      itemCount: cartProvider.cart.length,
                      itemBuilder: (context, index) {
                        final item = cartProvider.cart[index];
                        return ListTile(
                          leading: Image.network(item.product.image, width: 50),
                          title: Text(item.product.nameOfProduct),
                          subtitle: Text('Quantity: ${item.quantity}'),
                          trailing: Text(
                            '${item.product.price * item.quantity} DH',
                          ),
                        );
                      },
                    ),
                  ),
                 Padding(
  padding: const EdgeInsets.all(16.0),
  child: ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.green,
      padding: const EdgeInsets.symmetric(vertical: 16),
      textStyle: const TextStyle(fontSize: 18),
    ),
    onPressed: () async {
  final userId = cartProvider.userId;
  final cartId = cartProvider.cartId;

  if (userId == null || cartId == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please log in')),
    );
    return;
  }

  try {
    final isPaid = await StripeService.instance.makePayment();

    if (isPaid) {
      await orderProvider.placeOrder(
        userId,
        cartId,
        cartProvider.cart,
      );

      await cartProvider.clearCart();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Order placed and paid successfully'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ Payment failed.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('❌ Error placing order: $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
},

   
    child: const Center(child: Text('Confirm Order')),
  ),
)

                ],
              ),
    );
  }
}

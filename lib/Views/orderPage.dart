import 'package:flutter/material.dart';
import 'package:homepage/models/CartItem.dart';

class OrderPage extends StatelessWidget {
  final List<Cartitem> cartItems;
  final double totalAmount;

  const OrderPage({super.key, required this.cartItems, required this.totalAmount});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Summary'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Items:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) {
                  final item = cartItems[index];
                  return ListTile(
                    title: Text(item.product.nameOfProduct),
                    subtitle: Text('Quantity: ${item.quantity}'),
                    trailing: Text('${(item.product.price * item.quantity).toStringAsFixed(2)} MAD'),
                  );
                },
              ),
            ),
            const Divider(),
            Text(
              'Total: ${totalAmount.toStringAsFixed(2)} MAD',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  // Simulate payment process
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Payment processed successfully")),
                  );
                },
                child: const Text('Confirm & Pay'),
              ),
            )
          ],
        ),
      ),
    );
  }
}

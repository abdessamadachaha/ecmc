import 'package:flutter/material.dart';
import 'package:homepage/models/CartItem.dart';
import 'package:homepage/models/person.dart';
import 'package:homepage/homepage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class OrderPage extends StatelessWidget {
  final List<Cartitem> cartItems;
  final double totalAmount;

  const OrderPage({
    super.key,
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Order Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.black,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 8, bottom: 16),
              child: Text('Your Order', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            ),
            Expanded(
              child: cartItems.isEmpty
                  ? const Center(child: Text('Your cart is empty', style: TextStyle(color: Colors.grey)))
                  : ListView.builder(
                itemCount: cartItems.length,
                itemBuilder: (context, index) => _buildOrderItem(cartItems[index]),
              ),
            ),
            _buildTotalAndPayment(context),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItem(Cartitem item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(item.product.image, width: 60, height: 60, fit: BoxFit.cover),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.product.nameOfProduct, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text('Qty: ${item.quantity}', style: const TextStyle(color: Colors.grey)),
                ],
              ),
            ),
            Text(
              '${(item.product.price * item.quantity).toStringAsFixed(2)} MAD',
              style: const TextStyle(color: Colors.deepOrange, fontWeight: FontWeight.bold),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildTotalAndPayment(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10)],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              Text('${totalAmount.toStringAsFixed(2)} MAD', style: const TextStyle(color: Colors.deepOrange, fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _processPayment(context),
            child: const Center(child: Text('Confirm & Pay', style: TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
    );
  }

  void _processPayment(BuildContext context) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;

      if (userId == null) {
        _showDialog(context, false, null);
        return;
      }

      final data = await Supabase.instance.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final user = Person.fromMap(data);

      // Afficher le dialogue de succès
      _showDialog(context, true, user);

    } catch (e) {
      _showDialog(context, false, null);
    }
  }

  void _showDialog(BuildContext context, bool isSuccess, Person? user) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(isSuccess ? Icons.check_circle : Icons.error, color: isSuccess ? Colors.green : Colors.red),
            const SizedBox(width: 10),
            Text(isSuccess ? 'Payment Successful' : 'Payment Failed'),
          ],
        ),
        content: Text(
          isSuccess ? '${totalAmount.toStringAsFixed(2)} MAD processed successfully' : 'Payment failed. Please try again.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Fermer le dialogue
              if (isSuccess && user != null) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => Homepage(person: user!)),
                      (route) => false,
                );
              }
            },
            child: Text(isSuccess ? 'Continue Shopping' : 'Back'),
          )
        ],
      ),
    );
  }
}

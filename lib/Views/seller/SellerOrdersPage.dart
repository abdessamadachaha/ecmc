import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'SellerScaffold.dart';

class SellerOrdersPage extends StatefulWidget {
  const SellerOrdersPage({Key? key}) : super(key: key);

  @override
  State<SellerOrdersPage> createState() => _SellerOrdersPageState();
}

class _SellerOrdersPageState extends State<SellerOrdersPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _orderItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSellerOrders();
  }

  Future<void> _loadSellerOrders() async {
    setState(() => _isLoading = true);
    try {
      final sellerId = _supabase.auth.currentUser?.id;
      if (sellerId == null) return;

      final raw = await _supabase
          .from('order_item')
          .select('''
            id,
            quantity,
            unit_price,
            product (
              name,
              image
            ),
            order_id,
            orders (
              created_at,
              customer_id
            )
          ''')
          .eq('seller_id', sellerId);

      final rawList = List<Map<String, dynamic>>.from(raw as List);

      rawList.sort((a, b) {
        final aDate = DateTime.tryParse(a['orders']?['created_at'] ?? '');
        final bDate = DateTime.tryParse(b['orders']?['created_at'] ?? '');
        return (bDate ?? DateTime(1970)).compareTo(aDate ?? DateTime(1970));
      });

      setState(() => _orderItems = rawList);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Error loading orders: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _showCustomerInfo(String customerId) async {
    try {
      final data = await _supabase
          .from('users')
          .select('name, email, phone')
          .eq('id', customerId)
          .maybeSingle();

      if (data == null) {
        showDialog(
          context: context,
          builder: (_) => const AlertDialog(
            title: Text('Customer Info'),
            content: Text('Customer not found.'),
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('👤 Customer Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _infoRow(Icons.person, data['name'] ?? '—'),
              const SizedBox(height: 8),
              _infoRow(Icons.email, data['email'] ?? '—'),
              const SizedBox(height: 8),
              _infoRow(Icons.phone, data['phone'] ?? '—'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Failed to load customer: $e')),
      );
    }
  }

  Widget _infoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.blueAccent),
        const SizedBox(width: 8),
        Flexible(child: Text(text)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SellerScaffold(
      title: '📦 My Orders',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderItems.isEmpty
          ? const Center(child: Text('No orders found.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _orderItems.length,
        itemBuilder: (context, index) {
          final item = _orderItems[index];
          final product = item['product'];
          final order = item['orders'];
          final imageUrl = (product['image'] ?? '').toString().trim();
          final rawDate = order['created_at']?.toString();
          final dateTime = rawDate != null ? DateTime.tryParse(rawDate) : null;
          final formatted = dateTime != null
              ? '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')} '
              '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}'
              : '—';

          return Card(
            elevation: 3,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            shadowColor: Colors.blueGrey.withOpacity(0.15),
            margin: const EdgeInsets.only(bottom: 16),
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                final customerId = order['customer_id'];
                if (customerId != null) _showCustomerInfo(customerId);
              },
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: imageUrl.isNotEmpty
                          ? Image.network(
                        imageUrl,
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.broken_image, size: 40),
                      )
                          : Container(
                        width: 70,
                        height: 70,
                        color: Colors.grey[100],
                        child: const Icon(Icons.image, color: Colors.grey, size: 40),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product['name'] ?? 'Unnamed Product',
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              _chip('📦 Qty: ${item['quantity']}', Colors.blue.shade50, Colors.blue),
                              const SizedBox(width: 8),
                              _chip('💰 ${item['unit_price']} \$', Colors.green.shade50, Colors.green),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                              const SizedBox(width: 6),
                              Text(
                                formatted,
                                style: const TextStyle(fontSize: 13, color: Colors.black54),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _chip(String text, Color bg, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textColor),
      ),
    );
  }
}

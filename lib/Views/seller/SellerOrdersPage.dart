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
          builder: (_) => AlertDialog(
            title: const Text('Customer Info'),
            content: const Text('Customer not found.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
        return;
      }

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('Customer Info'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                const Icon(Icons.person, size: 20),
                const SizedBox(width: 8),
                Text(data['name'] ?? '—'),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.email, size: 20),
                const SizedBox(width: 8),
                Text(data['email'] ?? '—'),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.phone, size: 20),
                const SizedBox(width: 8),
                Text(data['phone'] ?? '—'),
              ]),
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
        SnackBar(content: Text('Failed to load customer: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return SellerScaffold(
      title: 'My Order Items',
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _orderItems.isEmpty
              ? const Center(child: Text('No orders found'))
              : ListView.builder(
                  padding: const EdgeInsets.all(12),
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
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      margin: const EdgeInsets.only(bottom: 12),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          final customerId = order['customer_id'];
                          if (customerId != null) _showCustomerInfo(customerId);
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(10),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        width: 60,
                                        height: 60,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Icon(Icons.broken_image),
                                      )
                                    : Container(
                                        width: 60,
                                        height: 60,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.image_not_supported),
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
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 8,
                                      children: [
                                        _chip('Qty: ${item['quantity']}', Colors.grey[200]!),
                                        _chip('💰 ${item['unit_price']} \$', Colors.grey[300]!),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '📅 Ordered: $formatted',
                                      style: const TextStyle(fontSize: 13, color: Colors.black54),
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(Icons.info_outline, color: Colors.black54),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }

  Widget _chip(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 12),
      ),
    );
  }
}

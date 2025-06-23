import 'package:flutter/material.dart';
import 'package:homepage/Views/admin/AdminDrawer.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminOrderItemsPage extends StatefulWidget {
  const AdminOrderItemsPage({Key? key}) : super(key: key);

  @override
  State<AdminOrderItemsPage> createState() => _AdminOrderItemsPageState();
}

class _AdminOrderItemsPageState extends State<AdminOrderItemsPage> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchOrderItems();
  }

  Future<void> _fetchOrderItems() async {
    setState(() => _loading = true);
    try {
      final raw = await _supabase
          .from('order_item')
          .select('''
            id,
            quantity,
            unit_price,
            order_id,
            product (
              name,
              image,
              id_seller
            ),
            orders (
              created_at,
              customer_id,
              total_price
            )
          ''')
          .order('created_at', referencedTable: 'orders');

      final items = List<Map<String, dynamic>>.from(raw as List);

      final customerIds = items.map((e) => e['orders']?['customer_id']).where((id) => id != null).toSet().toList();
      final sellerIds = items.map((e) => e['product']?['id_seller']).where((id) => id != null).toSet().toList();

      final customers = await _supabase.from('users').select('id, name, phone').inFilter('id', customerIds);
      final sellers = await _supabase.from('users').select('id, name, phone, email').inFilter('id', sellerIds);

      final customerMap = {for (final c in customers) c['id']: c};
      final sellerMap = {for (final s in sellers) s['id']: s};

      final enriched = items.map((item) {
        final order = item['orders'] ?? {};
        final product = item['product'] ?? {};
        final customer = customerMap[order['customer_id']] ?? {};
        final seller = sellerMap[product['id_seller']] ?? {};
        return {
          ...item,
          'customer': customer,
          'seller': seller,
        };
      }).toList();

      setState(() => _items = enriched);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load order items: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _showSellerInfo(Map<String, dynamic> seller) {
  showDialog(
    context: context,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Seller Details',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildInfoRow(
              icon: Icons.person_outline,
              label: 'Name',
              value: seller['name'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: seller['phone'] ?? 'N/A',
            ),
            const SizedBox(height: 12),
            _buildInfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: seller['email'] ?? 'N/A',
            ),
            const SizedBox(height: 24),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  backgroundColor: Colors.indigo.shade50,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Close',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildInfoRow({
  required IconData icon,
  required String label,
  required String value,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(
        icon,
        size: 20,
        color: Colors.black,
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey.shade800,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Management', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white)),
        backgroundColor: Colors.black,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.indigo.shade800, Colors.indigo.shade600],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _fetchOrderItems,
          ),
        ],
      ),
      drawer: const AdminDrawer(),
      body: Container(
        decoration: const BoxDecoration(color: Colors.white),
        child: _loading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.indigo.shade600)),
                    const SizedBox(height: 16),
                    Text('Loading Orders...', style: TextStyle(color: Colors.grey.shade600, fontSize: 16)),
                  ],
                ),
              )
            : _items.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text('No Orders Found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: Colors.grey.shade600)),
                        const SizedBox(height: 8),
                        Text('When orders are placed, they will appear here', style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _fetchOrderItems,
                    color: Colors.indigo.shade600,
                    child: ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final item = _items[index];
                        final order = item['orders'] ?? {};
                        final customer = item['customer'] ?? {};
                        final product = item['product'] ?? {};
                        final seller = item['seller'] ?? {};
                        final date = DateTime.tryParse(order['created_at'] ?? '');
                        final formattedDate = date != null ? DateFormat('MMM dd, yyyy • hh:mm a').format(date) : 'Unknown date';

                        return GestureDetector(
                          onTap: () => _showSellerInfo(seller),
                          child: Card(
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: Colors.grey.shade200, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.indigo.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          formattedDate,
                                          style: TextStyle(fontSize: 12, color: Colors.indigo.shade800, fontWeight: FontWeight.w500),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          color: Colors.grey.shade100,
                                        ),
                                        child: product['image'] != null
                                            ? ClipRRect(
                                                borderRadius: BorderRadius.circular(8),
                                                child: Image.network(product['image'], fit: BoxFit.cover),
                                              )
                                            : Center(
                                                child: Icon(Icons.shopping_bag_outlined, size: 32, color: Colors.grey.shade400),
                                              ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(product['name'] ?? 'Unknown Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                                            const SizedBox(height: 8),
                                            Row(
                                              children: [
                                                Text('Qty: ${item['quantity']}', style: TextStyle(color: Colors.grey.shade600)),
                                                const SizedBox(width: 16),
                                                Text(NumberFormat.currency(symbol: 'MAD ', decimalDigits: 2).format(item['unit_price']), style: TextStyle(color: Colors.grey.shade600)),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  const Divider(height: 1, thickness: 1),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    child: Column(
                                      children: [
                                        _buildCustomerInfoRow(icon: Icons.person_outline, label: 'Customer', value: customer['name'] ?? 'Unknown'),
                                        const SizedBox(height: 8),
                                        _buildCustomerInfoRow(icon: Icons.call, label: 'phone', value: customer['phone'] ?? 'Not provided'),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(color: Colors.grey.shade50, borderRadius: BorderRadius.circular(8)),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total Amount', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                                        Text(NumberFormat.currency(symbol: 'MAD ', decimalDigits: 2).format(order['total_price'] ?? 0), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.green)),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildCustomerInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade500),
        const SizedBox(width: 12),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              children: [
                TextSpan(text: '$label: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey.shade700)),
                TextSpan(text: value, style: TextStyle(color: Colors.grey.shade800)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

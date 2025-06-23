import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'SellerScaffold.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final SupabaseClient _supabase = Supabase.instance.client;

  int totalOrders = 0;
  int totalProducts = 0;
  double totalRevenue = 0.0;

  String sellerName = '';
  String sellerEmail = '';
  String sellerImageUrl = '';

  @override
  void initState() {
    super.initState();
    fetchDashboardData();
  }

  Future<void> fetchDashboardData() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return;

    final userData = await _supabase
        .from('users')
        .select()
        .eq('id', user.id)
        .maybeSingle();

    if (userData != null) {
      setState(() {
        sellerName = userData['name'] ?? '';
        sellerEmail = userData['email'] ?? '';
        sellerImageUrl = userData['image'] ?? ''; // ✅ تأكد من الاسم الصحيح
      });
    }

    final productResponse = await _supabase
        .from('product')
        .select('id')
        .eq('id_seller', user.id);

    final orderResponse = await _supabase
        .from('order_item')
        .select('unit_price, quantity')
        .eq('seller_id', user.id);

    double revenue = 0;
    for (var order in orderResponse) {
      final unitPrice = double.tryParse(order['unit_price'].toString()) ?? 0.0;
      final quantity = int.tryParse(order['quantity'].toString()) ?? 1;
      revenue += unitPrice * quantity;
    }

    if (mounted) {
      setState(() {
        totalProducts = productResponse.length;
        totalOrders = orderResponse.length;
        totalRevenue = revenue;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SellerScaffold(
      title: '📊 Dashboard',
      sellerName: sellerName,
      sellerEmail: sellerEmail,
      sellerImageUrl: sellerImageUrl,
      body: (sellerName.isEmpty)
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  DashboardBox(
                    icon: Icons.shopping_bag,
                    label: 'Orders',
                    countText: '$totalOrders',
                    color: Colors.deepPurple,
                    onTap: () => Navigator.pushNamed(context, '/orders'),
                  ),
                  const SizedBox(height: 16),
                  DashboardBox(
                    icon: Icons.category,
                    label: 'Products',
                    countText: '$totalProducts',
                    color: Colors.teal,
                    onTap: () => Navigator.pushNamed(context, '/product-list'),
                  ),
                  const SizedBox(height: 16),
                  DashboardBox(
                    icon: Icons.monetization_on,
                    label: 'Total Revenue',
                    countText: '${totalRevenue.toStringAsFixed(2)} MAD',
                    color: Colors.orange,
                    onTap: () {},
                  ),
                ],
              ),
            ),
    );
  }
}

class DashboardBox extends StatelessWidget {
  final IconData icon;
  final String label;
  final String countText;
  final Color color;
  final VoidCallback? onTap;

  const DashboardBox({
    super.key,
    required this.icon,
    required this.label,
    required this.countText,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 36, color: color),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
            ),
            const SizedBox(height: 8),
            Text(
              countText,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ],
        ),
      ),
    );
  }
}

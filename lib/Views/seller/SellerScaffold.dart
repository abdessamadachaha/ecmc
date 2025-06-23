import 'package:flutter/material.dart';

class SellerScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final Widget? floatingActionButton;

  // ✅ معلومات البائع القادمة من Supabase
  final String sellerName;
  final String sellerEmail;
  final String? sellerImageUrl;

  const SellerScaffold({
    Key? key,
    required this.title,
    required this.body,
    required this.sellerName,
    required this.sellerEmail,
    this.sellerImageUrl,
    this.floatingActionButton,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F9F9),
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      drawer: Drawer(
        child: Container(
          color: Colors.white,
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              DrawerHeader(
                decoration: const BoxDecoration(
                  color: Colors.black,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: sellerImageUrl != null && sellerImageUrl!.isNotEmpty
                          ? NetworkImage(sellerImageUrl!)
                          : const AssetImage('assets/images/avatar.png') as ImageProvider,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      sellerName,
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                    Text(
                      sellerEmail,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),
              _buildDrawerItem(
                context,
                icon: Icons.dashboard,
                label: 'Dashboard',
                route: '/dashboard',
              ),
              _buildDrawerItem(
                context,
                icon: Icons.list,
                label: 'My Products',
                route: '/product-list',
              ),
              _buildDrawerItem(
                context,
                icon: Icons.shopping_cart,
                label: 'Orders',
                route: '/orders',
              ),
              _buildDrawerItem(
                context,
                icon: Icons.person,
                label: 'Profile',
                route: '/profile',
              ),
              const Divider(),
              _buildDrawerItem(
                context,
                icon: Icons.logout,
                label: 'Logout',
                route: '/login',
                isLogout: true,
              ),
            ],
          ),
        ),
      ),
      body: body,
      floatingActionButton: floatingActionButton,
    );
  }

  Widget _buildDrawerItem(BuildContext context,
      {required IconData icon,
      required String label,
      required String route,
      bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Colors.black),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          color: isLogout ? Colors.red : Colors.black,
        ),
      ),
      onTap: () {
        Navigator.pop(context); // إغلاق الدروار
        if (isLogout) {
          Navigator.pushNamedAndRemoveUntil(context, route, (_) => false);
        } else {
          Navigator.pushNamed(context, route);
        }
      },
    );
  }
}

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final _supabase = Supabase.instance.client;
  List<Map<String, dynamic>> _users = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchUsers();
  }

  Future<void> _fetchUsers() async {
    setState(() => _loading = true);
    try {
      final response = await _supabase
          .from('users')
          .select('id, name, email, phone, role, is_banned')
          .neq('role', 'admin'); // Exclure les admins
      setState(() {
        _users = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to fetch users: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _toggleBanUser(String userId, bool isBanned) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isBanned ? 'Unban User' : 'Ban User'),
        content: Text(
            'Are you sure you want to ${isBanned ? 'unban' : 'ban'} this user?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirm')),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await _supabase
          .from('users')
          .update({'is_banned': !isBanned}).eq('id', userId);

      setState(() {
        final user = _users.firstWhere((u) => u['id'] == userId);
        user['is_banned'] = !isBanned;
      });

      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(isBanned
            ? '✅ User unbanned successfully'
            : '🚫 User banned successfully'),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('👨‍💼 Admin Dashboard'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, index) {
                final user = _users[index];
                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    title: Text(user['name'] ?? 'No Name'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Email: ${user['email']}'),
                        Text('Phone: ${user['phone'] ?? 'N/A'}'),
                        Text('Role: ${user['role']}'),
                        Text(
                          'Status: ${user['is_banned'] == true ? '🚫 Banned' : '✅ Active'}',
                          style: TextStyle(
                              color: user['is_banned'] == true
                                  ? Colors.red
                                  : Colors.green),
                        ),
                      ],
                    ),
                    trailing: TextButton.icon(
                      icon: Icon(user['is_banned'] == true
                          ? Icons.lock_open
                          : Icons.block),
                      label:
                          Text(user['is_banned'] == true ? 'Unban' : 'Ban'),
                      onPressed: () =>
                          _toggleBanUser(user['id'], user['is_banned'] == true),
                    ),
                  ),
                );
              },
            ),
    );
  }
}



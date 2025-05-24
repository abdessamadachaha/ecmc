import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthRedirectPage extends StatefulWidget {
  const AuthRedirectPage({super.key});

  @override
  State<AuthRedirectPage> createState() => _AuthRedirectPageState();
}

class _AuthRedirectPageState extends State<AuthRedirectPage> {
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkUserRole(); // S'assure que le context est disponible
    });
  }

  Future<void> _checkUserRole() async {
    final user = supabase.auth.currentUser;
    final session = supabase.auth.currentSession;
    debugPrint('🔐 Session : $session');

    if (user == null) {
      debugPrint('🔴 Aucun utilisateur connecté');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
      return;
    }

    try {
      final response = await supabase
          .from('users')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      debugPrint('📦 Résultat Supabase : $response');

      final role = (response?['role'] ?? '').toString().toLowerCase();
      debugPrint('🎯 Rôle récupéré de Supabase : $role');

      if (!mounted) return;

      if (role == 'customer') {
        debugPrint('✅ Redirection vers /home');
        Navigator.of(context).pushReplacementNamed('/home');
        
      } else {
        debugPrint('✅ Redirection vers /product-list');
        Navigator.of(context).pushReplacementNamed('/product-list');
        
      }
    } catch (e) {
      debugPrint('❌ Erreur pendant la redirection : $e');
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}

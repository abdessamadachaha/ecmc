import 'package:flutter/material.dart';
import 'package:homepage/Views/LoginScreen.dart';
import 'package:homepage/Views/page.dart';
import 'package:homepage/config/supbase_config.dart';
import 'package:homepage/providers/favorite_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:homepage/homepage.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supabase.initialize(
    url: SupbaseConfig.url,
    anonKey: SupbaseConfig.anonKey
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteProvider())
      ],
      child:
      MaterialApp(
        home: Homepage(),
        debugShowCheckedModeBanner: false,
    ));
  }
}

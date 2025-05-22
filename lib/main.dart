// import 'package:flutter/material.dart';
// import 'package:homepage/Views/auth/login.dart';
// import 'package:homepage/Views/page.dart';
// import 'package:homepage/config/supbase_config.dart';
// import 'package:homepage/providers/cart_provider.dart';
// import 'package:homepage/providers/favorite_provider.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import 'package:homepage/homepage.dart';
// import 'package:provider/provider.dart';

// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//   await Supabase.initialize(
//     url: SupbaseConfig.url,
//     anonKey: SupbaseConfig.anonKey
//   );
//   runApp(MyApp());
// }

// class MyApp extends StatelessWidget {
//   const MyApp({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => FavoriteProvider()),
//         ChangeNotifierProvider(create: (_) => CartProvider())
//       ],
//       child:
//       MaterialApp(
//         home: LoginPage(),
//         debugShowCheckedModeBanner: false,
//     ));
//   }
// }
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:homepage/homepage.dart';
import 'package:homepage/providers/cart_provider.dart';
import 'package:homepage/providers/favorite_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1️⃣ Your Supabase config
import 'config/supbase_config.dart';

// 2️⃣ All of your screens:
import 'Views/auth/login.dart';
import 'Views/auth/signup.dart';
import 'Views/auth/forgetPassword.dart';
import 'Views/CartDetails.dart';
import 'Views/DetailsScreen.dart';
import 'Views/favoriteScreen.dart';
import 'Views/page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupbaseConfig.url,
    anonKey: SupbaseConfig.anonKey,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider())
      ],
      child: MaterialApp(
        title: 'Your App Name',
        debugShowCheckedModeBanner: false,
      
        // 3️⃣ Start your user at the login screen:
        initialRoute: '/login',
      
        // 4️⃣ Map each route name to its widget:
        routes: {
          '/login':          (_) => const LoginPage(),
          '/signup':         (_) => const SignUpPage(),
          '/forgot-password':(_) => const ForgotPasswordPage(),
          '/cart-details':   (_) => const Cartdetails(),
          '/favorites':      (_) => const FacoriteScreen(),
        },
      
        // Optionally handle unknown routes:
        onUnknownRoute: (settings) {
          return MaterialPageRoute(
            builder: (_) => const LoginPage(),
          );
        },
      ),
    );
  }
}
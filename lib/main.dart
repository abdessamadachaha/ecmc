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
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:homepage/Views/ProfileScreen.dart';
import 'package:homepage/Views/admin/AdminAllOrdersPage.dart';
import 'package:homepage/Views/admin/AdminAllProductsPage.dart';
import 'package:homepage/Views/admin/dashbord.dart';
import 'package:homepage/Views/admin/profile.dart';
import 'package:homepage/Views/auth/auth_redirect.dart';
import 'package:homepage/Views/seller/ProductList.dart';
import 'package:homepage/Views/seller/ProfilePage.dart';
import 'package:homepage/Views/seller/SellerOrdersPage.dart';
import 'package:homepage/Views/seller/addProdact.dart';
import 'package:homepage/consts.dart';
import 'package:homepage/homepage.dart';
import 'package:homepage/providers/cart_provider.dart';
import 'package:homepage/providers/favorite_provider.dart';
import 'package:homepage/providers/order_provider.dart';
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

  await _setUp();

  runApp(const MyApp());
}

Future<void> _setUp() async {
  WidgetsFlutterBinding.ensureInitialized();
  Stripe.publishableKey = stripePublishableKey;
  
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => FavoriteProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => OrderProvider()),
      ],
      child: MaterialApp(
        title: 'Your App Name',
        debugShowCheckedModeBanner: false,

        // 3️⃣ Start your user at the login screen:
        initialRoute: '/login',
        routes: {
          '/redirect': (_) => const AuthRedirectPage(),
          '/login': (_) => const LoginPage(),
          '/signup': (_) => const SignUpPage(),
          '/forgot-password': (_) => const ForgotPasswordPage(),
          '/product-list': (_) => const ProductListScreen(),
          '/add': (_) => const AddProductScreen(),
          '/profile': (_) => const ProfilePage(),
          '/orders': (_) => const SellerOrdersPage(),
          '/admin-dashboard': (_) => const AdminDashboard(),
          '/admin-profile': (context) => const AdminProfilePage(),
          '/all-products': (context) => AdminAllProductsPage(),
          '/all-order-items': (context) => const AdminOrderItemsPage(),
        },

        // Optionally handle unknown routes:
        onUnknownRoute: (settings) {
          return MaterialPageRoute(builder: (_) => const LoginPage());
        },
      ),
    );
  }
}

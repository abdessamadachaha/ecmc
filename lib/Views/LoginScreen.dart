// // views/LoginScreen.dart
// import 'package:flutter/material.dart';
// import 'package:homepage/Views/page.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';
// import '../models/person.dart';

// class LoginScreen extends StatefulWidget {
//   @override
//   State<LoginScreen> createState() => _LoginScreenState();
// }

// class _LoginScreenState extends State<LoginScreen> {
//   final emailController = TextEditingController();
//   final passwordController = TextEditingController();

//   bool isLoading = false;
//   String? errorMessage;

//   void login() async {
//     setState(() {
//       isLoading = true;
//       errorMessage = null;
//     });

//     try {
//       final response = await Supabase.instance.client.auth.signInWithPassword(
//         email: emailController.text.trim(),
//         password: passwordController.text.trim(),
//       );

//       final user = response.user;

//       if (user == null) {
//         setState(() {
//           errorMessage = 'Login failed. User not found.';
//           isLoading = false;
//         });
//         return;
//       }

//       // Get customer info from users table
//       final userData = await Supabase.instance.client
//           .from('users')
//           .select('*')
//           .eq('id', user.id)
//           .eq('role', 'customer')
//           .single();

//       final customer = Person.fromMap(userData);

//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => PageCategory(customer: customer),
//         ),
//       );
//     } catch (e) {
//       setState(() {
//         errorMessage = 'Login failed: ${e.toString()}';
//         isLoading = false;
//       });
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Login")),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           children: [
//             TextField(
//               controller: emailController,
//               decoration: const InputDecoration(labelText: 'Email'),
//             ),
//             const SizedBox(height: 16),
//             TextField(
//               controller: passwordController,
//               decoration: const InputDecoration(labelText: 'Password'),
//               obscureText: true,
//             ),
//             const SizedBox(height: 24),
//             if (errorMessage != null)
//               Text(errorMessage!, style: TextStyle(color: Colors.red)),
//             ElevatedButton(
//               onPressed: isLoading ? null : login,
//               child: isLoading
//                   ? CircularProgressIndicator(color: Colors.white)
//                   : const Text("Login"),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

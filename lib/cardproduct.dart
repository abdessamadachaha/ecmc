// import 'package:flutter/material.dart';

// class productcard extends StatefulWidget {
//   const productcard({super.key});

//   @override
//   State<productcard> createState() => _productcardState();
// }

// class _productcardState extends State<productcard> {

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: MediaQuery.of(context).size.width / 2,
//       decoration: BoxDecoration(
//         borderRadius: BorderRadius.circular(8.0),
//         color: Colors.grey.withOpacity(0.1),
//       ),
//       child: Column(
//         children: [
//           SizedBox(
//             height: 130,
//             width: 130,
//             child: Image(
//               image: NetworkImage(product['image']),
//               fit: BoxFit.cover,
//             ),
//           ),
//           SizedBox(height: 8.0),

//           Text(
//             product['name'] ?? '',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16.0),
//           ),

//           Text(
//             '${product['price']}MAD',
//             style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18.0),
//           ),
//         ],
//       ),
//     );
//   }
// }

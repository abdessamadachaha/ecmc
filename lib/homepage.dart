import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:homepage/Views/CartDetails.dart';
import 'package:homepage/Views/ProfileScreen.dart';
import 'package:homepage/Views/page.dart';
import 'package:homepage/Views/favoriteScreen.dart';
import 'package:homepage/models/person.dart';

class Homepage extends StatefulWidget {
  final Person person;

  
  Homepage({super.key, required this.person});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Color tapIcon = Colors.black;
  int selectIndex = 0;
  final items = [
    Icon(LucideIcons.house,color: Colors.white,  size: 24,),
    Icon(LucideIcons.heart,color: Colors.white, size: 24,),
    Icon(LucideIcons.shopping_cart,color: Colors.white, size: 24,),
    Icon(LucideIcons.user,color: Colors.white, size: 24,),
    
  ];
  @override
  Widget build(BuildContext context) {
    final pages = [CategoryPage(person: widget.person,), FavoriteScreen(), Cartdetails(), ProfileScreen(person: widget.person)];

    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: pages[selectIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.black,
        index: selectIndex,
        height: 55,
        items: items,
        onTap: (index) {
          setState(() {
            selectIndex = index;
          });
        },
      ),
    );
  }
}

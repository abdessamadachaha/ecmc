import 'package:flutter/material.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:homepage/Views/page.dart';
import 'package:homepage/Views/favoriteScreen.dart';
import 'package:homepage/models/person.dart';

class Homepage extends StatefulWidget {
  
  const Homepage({super.key});

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  Color tapIcon = Colors.black;
  int selectIndex = 0;
  final pages = [PageCategory(), FacoriteScreen(), PageCategory(), PageCategory()];
  final items = [
    Icon(LucideIcons.house, size: 24,),
    Icon(LucideIcons.heart, size: 24,),
    Icon(LucideIcons.shopping_cart, size: 24,),
    Icon(LucideIcons.user, size: 24,),
    
  ];
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: Colors.white,
      body: pages[selectIndex],
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Color.fromARGB(255, 243, 243, 243),
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

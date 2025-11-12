import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/pages/home.dart';
import 'package:e_commerce_app/pages/order.dart'; // This is your Cart Page
import 'package:e_commerce_app/pages/profile.dart';
import 'package:e_commerce_app/pages/wallet.dart';

class BottomNav extends StatefulWidget {
  // 1. Added optional parameter for external navigation
  final int initialIndex;
  const BottomNav({super.key, this.initialIndex = 0});

  @override
  State<BottomNav> createState() => _BottomNavState();
}

class _BottomNavState extends State<BottomNav> {
  // Define the theme color used in home.dart
  final Color _themeOrange = const Color(0xFFff5c30);
  // Define the new, professional Deep Dark Grey color for the nav bar
  final Color _navColor = const Color(0xFF333333);

  int currentTabIndex = 0;

  late List<Widget> pages;
  late Home homepage;
  late Order order; // This is the Cart page
  late Profile profile;
  late Wallet wallet;

  @override
  void initState() {
    homepage = Home();
    order = Order();
    profile = Profile();
    wallet = Wallet();

    // 2. Set the starting tab based on the initialIndex parameter
    currentTabIndex = widget.initialIndex;

    // Pages list: [Home, Cart (Order), Wallet, Profile]
    pages = [homepage, order, wallet, profile];
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true, // Allows the body to go behind the transparent nav bar area
      bottomNavigationBar: CurvedNavigationBar(
        index: currentTabIndex,
        height: 65,
        backgroundColor: Colors.transparent, // Attractive: transparent background
        color: _navColor, // 🎯 Applied Deep Dark Grey color here
        buttonBackgroundColor: _themeOrange, // Keep the button color the theme orange
        animationDuration: Duration(milliseconds: 400),
        onTap: (int index) {
          setState(() {
            currentTabIndex = index;
          });
        },
        items: [
          Icon(Icons.home_outlined, color: Colors.white, size: 28),         // Index 0: Home
          Icon(Icons.shopping_cart_outlined, color: Colors.white, size: 28), // Index 1: Cart (Order.dart)
          Icon(Icons.wallet_outlined, color: Colors.white, size: 28),       // Index 2: Wallet
          Icon(Icons.person_outline, color: Colors.white, size: 28),        // Index 3: Profile
        ],
      ),
      body: pages[currentTabIndex],
    );
  }
}
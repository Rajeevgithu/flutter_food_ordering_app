import 'package:e_commerce_app/pages/order.dart';
import 'package:e_commerce_app/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'package:e_commerce_app/firebase_options.dart';
import 'package:e_commerce_app/admin/admin_login.dart';
import 'package:e_commerce_app/admin/home_admin.dart';
import 'package:e_commerce_app/admin/add_food.dart';
import 'package:e_commerce_app/pages/bottomnav.dart';
import 'package:e_commerce_app/pages/login.dart';
import 'package:e_commerce_app/pages/onboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  //  Load environment variables
  await dotenv.load(fileName: ".env");

  //  Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  //  Load stored user data (for role-based startup)
  final prefs = await SharedPreferences.getInstance();
  final bool isOnboarded = prefs.getBool('isOnboarded') ?? false;
  final String? role = prefs.getString('role'); // 'admin' or 'user'

  Widget initialScreen;

  //  Role-based redirection
  if (!isOnboarded) {
    initialScreen = const Onboard();
  } else if (role == 'admin') {
    initialScreen = const HomeAdmin();
  } else if (role == 'user') {
    initialScreen = const BottomNav();
  } else {
    initialScreen = const Onboard(); // Default to login
  }

  runApp(MyApp(initialScreen: initialScreen));
}

class MyApp extends StatelessWidget {
  final Widget initialScreen;
  const MyApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'E-Commerce App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: initialScreen,
      routes: {
        //  Common Routes
        '/LogIn': (context) => const LogIn(),
        '/onboard': (context) => const Onboard(),
        '/bottomNav': (context) => const BottomNav(),

        // Admin Routes
        '/adminLogin': (context) => const AdminLogin(),
        '/adminHome': (context) => const HomeAdmin(),
        '/addFood': (context) => const AddFood(),

        //  User Routes
        '/Order': (context) => const Order(),
      },
    );
  }
}

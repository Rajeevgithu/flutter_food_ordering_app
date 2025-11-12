import 'package:e_commerce_app/pages/order.dart';
import 'package:e_commerce_app/pages/signup.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // 🎯 Import Stripe

import 'package:e_commerce_app/firebase_options.dart';
import 'package:e_commerce_app/admin/admin_login.dart';
import 'package:e_commerce_app/admin/home_admin.dart';
import 'package:e_commerce_app/admin/add_food.dart';
import 'package:e_commerce_app/pages/bottomnav.dart';
import 'package:e_commerce_app/pages/login.dart';
import 'package:e_commerce_app/pages/onboard.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load environment variables
  await dotenv.load(fileName: ".env");

  // --- FIX START ---
  // Safely retrieve the publishable key and check for null
  final stripeKey = dotenv.env['STRIPE_PUBLISHABLE_KEY'];

  if (stripeKey == null || stripeKey.isEmpty) {
    // Print a clear, custom error message to the console instead of crashing
    // This helps in debugging deployment issues where the .env file might be missing.
    print('FATAL CONFIGURATION ERROR: STRIPE_PUBLISHABLE_KEY not found in .env file.');
    // You might want to halt the app or display a user-friendly error screen here
    // if payment processing is essential, but for now, we prevent the crash.
  } else {
    // 1. Set the Publishable Key (static property - REQUIRED)
    Stripe.publishableKey = stripeKey;
    // 2. Initialize the Stripe instance (optional, often not needed for web)
    // Stripe.instance.initialize(
    //   publishableKey: stripeKey,
    // );
  }
  // --- FIX END ---

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Load stored user data (for role-based startup)
  final prefs = await SharedPreferences.getInstance();
  final bool isOnboarded = prefs.getBool('isOnboarded') ?? false;
  final String? role = prefs.getString('role'); // 'admin' or 'user'

  Widget initialScreen;

  // Role-based redirection
  if (!isOnboarded) {
    initialScreen = const Onboard();
  } else if (role == 'admin') {
    initialScreen = const HomeAdmin();
  } else if (role == 'user') {
    initialScreen = const BottomNav();
  } else {
    initialScreen = const Onboard(); // Default to onboard screen
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
        // Common Routes
        '/LogIn': (context) => const LogIn(),
        '/onboard': (context) => const Onboard(),
        '/bottomNav': (context) => const BottomNav(),

        // Admin Routes
        '/adminLogin': (context) => const AdminLogin(),
        '/adminHome': (context) => const HomeAdmin(),
        '/addFood': (context) => const AddFood(),

        // User Routes
        '/Order': (context) => const Order(),
        '/SignUp': (context) => const SignUp(),
      },
    );
  }
}
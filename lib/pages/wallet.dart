import 'dart:async';
import 'dart:convert'; // Required for JSON encoding/decoding
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
// ⚠️ IMPORTANT: Assuming you use the flutter_stripe package for payment
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/widget/widget_support.dart';
import 'package:http/http.dart' as http; // Required for API calls

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  // Theme Color
  final Color _themeOrange = const Color(0xFFff5c30);

  String? wallet = "0", id;
  int? currentWalletBalance;
  bool _isLoading = true;
  final TextEditingController amountController = TextEditingController();

  // Load Secret Key from .env once
  final String _stripeSecretKey = dotenv.env['STRIPE_SECRET_KEY'] ?? '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // Stripe initialization (using Publishable Key)
    Stripe.publishableKey = dotenv.env['STRIPE_PUBLISHABLE_KEY']!;
  }

  Future<void> _loadUserData() async {
    // ... (omitted for brevity, remains the same)
    try {
      id = await SharedPreferenceHelper().getUserId();
      wallet = await SharedPreferenceHelper().getUserWallet();
      currentWalletBalance = int.tryParse(wallet ?? "0");
      debugPrint("Loaded Wallet: ₹$wallet");
    } catch (e) {
      debugPrint("❌ Error loading shared prefs: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshWallet() async {
    // ... (omitted for brevity, remains the same)
    wallet = await SharedPreferenceHelper().getUserWallet();
    currentWalletBalance = int.tryParse(wallet ?? "0");
    if (mounted) setState(() {});
  }

  // ==============================
  // 🔒 Internal "Backend" Simulation
  // WARNING: In a production app, this entire function
  // MUST run on a secure server, NOT in Flutter code.
  // ==============================
  Future<String> _createPaymentIntent(int amountInRupees) async {
    if (_stripeSecretKey.isEmpty) {
      throw Exception("Stripe Secret Key not found. Check .env and main.dart.");
    }

    // Stripe requires amount in the smallest currency unit (paise/cents)
    final amountInPaise = amountInRupees * 100;

    final response = await http.post(
      Uri.parse('https://api.stripe.com/v1/payment_intents'),
      headers: {
        // This is where the SECRET key is used. Keep it hidden!
        'Authorization': 'Bearer $_stripeSecretKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'amount': amountInPaise.toString(),
        'currency': 'inr',
        'payment_method_types[]': 'card',
        'description': 'E-commerce wallet top-up',
      },
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return responseBody['client_secret'];
    } else {
      final errorMessage = responseBody['error']['message'] ?? 'Unknown Stripe API error';
      debugPrint('Stripe API Error: ${response.statusCode} - $errorMessage');
      throw Exception('Failed to create Payment Intent: $errorMessage');
    }
  }

  // ==============================
  // 💸 Stripe Payment Logic
  // ==============================
  Future<void> makeStripePayment(String amountStr) async {
    final int amount = int.tryParse(amountStr) ?? 0;
    if (amount <= 0 || id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid amount or user data missing.")),
      );
      return;
    }

    String? clientSecret;

    try {
      // 1. Create Payment Intent using the internal, simulated backend function
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Initiating payment... Please wait.")),
      );

      clientSecret = await _createPaymentIntent(amount);

      // 2. Initialize Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'Food Delivery App',
          customerId: id,
          customFlow: false,
          style: ThemeMode.light,
        ),
      );

      // 3. Display Payment Sheet
      await Stripe.instance.presentPaymentSheet();

      // 4. Payment successful! Update Wallet Balance
      if (!mounted) return;

      final int newBalance = currentWalletBalance! + amount;
      await SharedPreferenceHelper().saveUserWallet(newBalance.toString());
      await DatabaseMethods().updateUserWallet(id!, newBalance.toString());
      await _refreshWallet();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("✅ ₹$amount added successfully! Wallet updated!"),
          backgroundColor: Colors.green,
        ),
      );

    } on StripeException catch (e) {
      debugPrint("Stripe Payment Error: ${e.error.localizedMessage}");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment Failed: ${e.error.localizedMessage}"),
          backgroundColor: Colors.redAccent,
        ),
      );
    } catch (e) {
      debugPrint("General Payment Error: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Payment failed! Check connection or keys: $e"),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }


  // ==============================
  // 🧾 Manual Amount Dialog (omitted for brevity, remains the same)
  // ==============================
  Future openEdit() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      contentPadding: const EdgeInsets.all(20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Add Custom Amount",
                style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18, color: _themeOrange),
              ),
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 30),
          Text("Amount (in INR)", style: AppWidget.LightTextFeildStyle()),
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300, width: 1.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: amountController,
              decoration: const InputDecoration(
                border: InputBorder.none,
                hintText: 'e.g., 250',
                prefixText: '₹ ',
              ),
              keyboardType: TextInputType.number,
              style: AppWidget.semiBoldTextFeildStyle(),
            ),
          ),
          const SizedBox(height: 30.0),
          Center(
            child: GestureDetector(
              onTap: () {
                final amountText = amountController.text;
                if (amountText.isEmpty || int.tryParse(amountText) == null || int.parse(amountText) <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a valid amount")),
                  );
                  return;
                }
                Navigator.pop(context);
                makeStripePayment(amountText);
                amountController.clear(); // Clear input after successful action
              },
              child: Container(
                width: 150,
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _themeOrange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text(
                      "Pay Now",
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  // ==============================
  // 💳 Wallet Card Widget (omitted for brevity, remains the same)
  // ==============================
  Widget _buildWalletCard() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      margin: const EdgeInsets.symmetric(horizontal: 20.0),
      width: MediaQuery.of(context).size.width,
      decoration: BoxDecoration(
        color: _themeOrange, // Use theme orange for a branded card
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [_themeOrange, const Color(0xFFe74b1a)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: _themeOrange.withOpacity(0.4),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Your Wallet Balance",
                style: AppWidget.LightTextFeildStyle().copyWith(
                  color: Colors.white70,
                  fontSize: 16,
                ),
              ),
              const Icon(Icons.account_balance_wallet, color: Colors.white, size: 30),
            ],
          ),
          const SizedBox(height: 15.0),
          Text(
            "₹${wallet ?? "0"}",
            style: AppWidget.boldTextFeildStyle().copyWith(
              color: Colors.white,
              fontSize: 32,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 5.0),
          Text(
            "Available Balance",
            style: AppWidget.LightTextFeildStyle().copyWith(
              color: Colors.white.withOpacity(0.8),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  // ==============================
  // 💰 Quick Add Button (omitted for brevity, remains the same)
  // ==============================
  Widget _amountBox(String amount) {
    return GestureDetector(
      onTap: _isLoading || id == null
          ? () {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Please wait, data not loaded yet."),
          ),
        );
      }
          : () => makeStripePayment(amount),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300, width: 1),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 5,
            ),
          ],
        ),
        child: Text(
            "₹$amount",
            style: AppWidget.semiBoldTextFeildStyle().copyWith(color: _themeOrange)
        ),
      ),
    );
  }

  Widget _buildSkeletonUI() {
    // Improved Skeleton Loader
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      children: [
        Container(height: 150, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(20))),
        const SizedBox(height: 40),
        Container(height: 20, width: 150, color: Colors.grey.shade200),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(4, (index) => Container(height: 40, width: 70, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(10)))),
        ),
        const SizedBox(height: 50),
        Container(height: 55, decoration: BoxDecoration(color: Colors.grey.shade200, borderRadius: BorderRadius.circular(15))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: _isLoading
          ? _buildSkeletonUI()
          : SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Header ---
            Container(
              padding: const EdgeInsets.only(top: 60, bottom: 20, left: 20, right: 20),
              child: Text(
                "My Wallet",
                style: AppWidget.HeadlineTextFeildStyle().copyWith(color: Colors.black, fontSize: 28),
              ),
            ),

            // --- 💳 Wallet Card ---
            _buildWalletCard(),

            const SizedBox(height: 40.0),

            // --- Quick Add Section ---
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "Quick Top-up",
                style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 15.0),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _amountBox("100"),
                _amountBox("500"),
                _amountBox("1000"),
                _amountBox("2000"),
              ],
            ),

            const SizedBox(height: 30.0),

            // --- Add Custom Amount Button ---
            GestureDetector(
              onTap: openEdit,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20.0),
                padding: const EdgeInsets.symmetric(vertical: 15.0),
                width: MediaQuery.of(context).size.width,
                decoration: BoxDecoration(
                    color: _themeOrange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: _themeOrange, width: 1.5)
                ),
                child: Center(
                  child: Text(
                    "Add Custom Amount",
                    style: AppWidget.boldTextFeildStyle().copyWith(
                      color: _themeOrange,
                      fontSize: 16.0,
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 40.0),

            // --- Transaction History Placeholder ---
            Padding(
              padding: const EdgeInsets.only(left: 20.0, right: 20.0),
              child: Text(
                "Recent Transactions",
                style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18),
              ),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: Text(
                "No recent activity to display.",
                style: AppWidget.LightTextFeildStyle().copyWith(color: Colors.grey[600]),
              ),
            ),

            const SizedBox(height: 50.0), // Padding for bottom nav bar
          ],
        ),
      ),
    );
  }
}
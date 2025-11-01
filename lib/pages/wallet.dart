import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_paypal_payment/flutter_paypal_payment.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/widget/widget_support.dart';

class Wallet extends StatefulWidget {
  const Wallet({super.key});

  @override
  State<Wallet> createState() => _WalletState();
}

class _WalletState extends State<Wallet> {
  String? wallet = "0", id;
  int? add;
  bool _isLoading = true;
  final TextEditingController amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      id = await SharedPreferenceHelper().getUserId();
      wallet = await SharedPreferenceHelper().getUserWallet();

      if (id == null) {
        debugPrint("⚠️ User ID not found. User may not be logged in.");
      }
    } catch (e) {
      debugPrint("❌ Error loading shared prefs: $e");
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshWallet() async {
    wallet = await SharedPreferenceHelper().getUserWallet();
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? _buildSkeletonUI()
          : Container(
              margin: const EdgeInsets.only(top: 60.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Material(
                    elevation: 2.0,
                    child: Container(
                      padding: const EdgeInsets.only(bottom: 10.0),
                      child: Center(
                        child: Text(
                          "Wallet",
                          style: AppWidget.HeadlineTextFeildStyle(),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30.0),

                  // 💳 Wallet Display
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10.0,
                      horizontal: 10.0,
                    ),
                    width: MediaQuery.of(context).size.width,
                    decoration: const BoxDecoration(color: Color(0xFFF2F2F2)),
                    child: Row(
                      children: [
                        Image.asset(
                          "images/wallet.png",
                          height: 60,
                          width: 60,
                          fit: BoxFit.cover,
                        ),
                        const SizedBox(width: 40.0),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Your Wallet",
                              style: AppWidget.LightTextFeildStyle(),
                            ),
                            const SizedBox(height: 5.0),
                            Text(
                              "₹${wallet ?? "0"}",
                              style: AppWidget.boldTextFeildStyle(),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20.0),
                  const Padding(
                    padding: EdgeInsets.only(left: 20.0),
                    child: Text(
                      "Add money",
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10.0),

                  // 💰 Quick Add Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _amountBox("100"),
                      _amountBox("500"),
                      _amountBox("1000"),
                      _amountBox("2000"),
                    ],
                  ),

                  const SizedBox(height: 50.0),

                  // 🧾 Custom Add Button
                  GestureDetector(
                    onTap: _isLoading || id == null
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  "Please wait, user not loaded yet.",
                                ),
                              ),
                            );
                          }
                        : openEdit,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20.0),
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      width: MediaQuery.of(context).size.width,
                      decoration: BoxDecoration(
                        color: const Color(0xFF008080),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Center(
                        child: Text(
                          "Add Money",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _amountBox(String amount) {
    return GestureDetector(
      onTap: _isLoading || id == null
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text("Please wait, user not loaded yet."),
                ),
              );
            }
          : () => makePaypalPayment(amount),
      child: Container(
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE9E2E2)),
          borderRadius: BorderRadius.circular(5),
        ),
        child: Text("₹$amount", style: AppWidget.semiBoldTextFeildStyle()),
      ),
    );
  }

  Widget _buildSkeletonUI() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 80),
      itemCount: 3,
      itemBuilder: (_, __) => Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        height: 80,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ==============================
  // 💸 PayPal Payment Logic
  // ==============================
  void makePaypalPayment(String amount) async {
    // 🧠 Force reload shared preferences before using
    id ??= await SharedPreferenceHelper().getUserId();
    wallet ??= await SharedPreferenceHelper().getUserWallet();

    if (id == null) {
      debugPrint("❌ User ID is null — cannot proceed.");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("⚠️ Please log in again.")));
      return;
    }

    if (amount.isEmpty || int.tryParse(amount) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid amount.")),
      );
      return;
    }

    // ✅ Continue to PayPal checkout only if ID exists
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PaypalCheckoutView(
          sandboxMode: true,
          clientId: dotenv.env['PAYPAL_CLIENT_ID']!,
          secretKey: dotenv.env['PAYPAL_SECRET_KEY']!,
          transactions: [
            {
              "amount": {
                "total": amount,
                "currency": "USD",
                "details": {
                  "subtotal": amount,
                  "shipping": '0',
                  "shipping_discount": 0,
                },
              },
              "description": "Wallet Top-up",
            },
          ],
          note: "Contact support for help.",
          onSuccess: (Map params) async {
            Navigator.pop(context);
            debugPrint("✅ Payment Success: $params");

            add = (int.tryParse(wallet ?? "0") ?? 0) + int.parse(amount);
            await SharedPreferenceHelper().saveUserWallet(add.toString());
            await DatabaseMethods().updateUserWallet(id!, add.toString());
            wallet = add.toString();

            if (!mounted) return;

            showDialog(
              context: context,
              builder: (_) => const AlertDialog(
                content: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green),
                    SizedBox(width: 8),
                    Text("Payment Successful"),
                  ],
                ),
              ),
            );

            await _refreshWallet();
          },
          onError: (error) {
            debugPrint("❌ Payment Error: $error");
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Payment failed!")));
          },
          onCancel: () {
            debugPrint("🚫 Payment Cancelled");
            Navigator.pop(context);
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(const SnackBar(content: Text("Payment cancelled.")));
          },
        ),
      ),
    );
  }

  // ==============================
  // 🧾 Manual Amount Dialog
  // ==============================
  Future openEdit() => showDialog(
    context: context,
    builder: (context) => AlertDialog(
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.cancel),
                ),
                const SizedBox(width: 60.0),
                const Center(
                  child: Text(
                    "Add Money",
                    style: TextStyle(
                      color: Color(0xFF008080),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            const Text("Amount"),
            const SizedBox(height: 10.0),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10.0),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.black38, width: 2.0),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'Enter Amount',
                ),
                keyboardType: TextInputType.number,
              ),
            ),
            const SizedBox(height: 20.0),
            Center(
              child: GestureDetector(
                onTap: () {
                  if (amountController.text.isEmpty ||
                      int.tryParse(amountController.text) == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Enter a valid amount")),
                    );
                    return;
                  }
                  Navigator.pop(context);
                  makePaypalPayment(amountController.text);
                },
                child: Container(
                  width: 100,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFF008080),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Text("Pay", style: TextStyle(color: Colors.white)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

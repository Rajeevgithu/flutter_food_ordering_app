import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/widget/widget_support.dart';
import 'package:e_commerce_app/pages/details.dart';

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
  // Define the theme color used in home.dart
  final Color _themeOrange = const Color(0xFFff5c30);

  String? id, wallet;
  Stream? foodStream;

  @override
  void initState() {
    super.initState();
    onTheLoad();
  }

  Future<void> getSharedPref() async {
    id = await SharedPreferenceHelper().getUserId();
    wallet = await SharedPreferenceHelper().getUserWallet();
  }

  Future<void> onTheLoad() async {
    await getSharedPref();
    if (id != null) {
      foodStream = DatabaseMethods().getFoodCart(id!);
      setState(() {});
    }
  }

  Future<void> _removeItem(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection("user")
          .doc(id)
          .collection("cart")
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("🗑️ Item removed from cart"),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.red,
          content: Text("❌ Error removing item: $e"),
        ),
      );
    }
  }

  // Helper method to parse the total amount safely
  int _calculateTotal(QuerySnapshot snapshot) {
    int total = 0;
    for (var doc in snapshot.docs) {
      final cleanTotal = doc["Total"].toString().replaceAll(RegExp(r'[^0-9]'), '');
      total += int.tryParse(cleanTotal) ?? 0;
    }
    return total;
  }

  Widget foodCart() {
    return StreamBuilder(
      stream: foodStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: _themeOrange));
        }
        if (!snapshot.hasData || snapshot.data.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                const SizedBox(height: 10),
                Text(
                  "Your cart is empty!",
                  style: AppWidget.semiBoldTextFeildStyle().copyWith(color: Colors.grey[700], fontSize: 20),
                ),
                Text(
                  "Add some delicious items from the Home page.",
                  style: AppWidget.LightTextFeildStyle().copyWith(color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final int total = _calculateTotal(snapshot.data as QuerySnapshot);

        // 🎯 FIX APPLIED HERE: Padding to prevent bottom nav overlap
        return Padding(
          padding: const EdgeInsets.only(bottom: 95.0),
          child: Column(
            children: [
              // 🧾 CART LIST
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
                  itemCount: snapshot.data.docs.length,
                  itemBuilder: (context, index) {
                    DocumentSnapshot ds = snapshot.data.docs[index];
                    final cleanTotal = ds["Total"].toString().replaceAll(RegExp(r'[^0-9]'), '');

                    return Container(
                      margin: const EdgeInsets.only(bottom: 15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // 🖼️ Product Image
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => Details(
                                      image: ds["Image"],
                                      name: ds["Name"],
                                      detail:
                                      "Delicious ${ds["Name"]} freshly prepared just for you!",
                                      price: ds["PricePerUnit"].toString(),
                                    ),
                                  ),
                                );
                              },
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.network(
                                  ds["Image"],
                                  height: 90,
                                  width: 90,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.broken_image, size: 60, color: Colors.redAccent),
                                ),
                              ),
                            ),

                            const SizedBox(width: 16),

                            // 📝 Product Info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ds["Name"].toString(),
                                    style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 17),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Unit Price: ₹${ds["PricePerUnit"]}",
                                    style: AppWidget.LightTextFeildStyle().copyWith(fontSize: 13, color: Colors.grey[600]),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Quantity Label
                                      Text(
                                        "Qty: ${ds["Quantity"]}",
                                        style: AppWidget.LightTextFeildStyle().copyWith(fontSize: 14, color: Colors.black),
                                      ),
                                      // Total Price for this item
                                      Text(
                                        "₹$cleanTotal",
                                        style: AppWidget.boldTextFeildStyle().copyWith(
                                          fontSize: 18,
                                          color: _themeOrange, // Use theme orange for price
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            // ❌ Remove Button
                            IconButton(
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    title: const Text("Remove Item?"),
                                    content: Text(
                                      "Are you sure you want to remove ${ds["Name"]}?",
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.pop(context), // Cancel
                                        child: const Text("Cancel"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.redAccent,
                                        ),
                                        onPressed: () {
                                          Navigator.pop(context);
                                          _removeItem(ds.id);
                                        },
                                        child: const Text("Remove"),
                                      ),
                                    ],
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              // 💵 TOTAL SUMMARY
              Container(
                margin: const EdgeInsets.only(
                  left: 20.0,
                  right: 20.0,
                  bottom: 10.0,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 18.0,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Total Amount:",
                      style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18, color: Colors.black),
                    ),
                    Text(
                      "₹$total",
                      style: AppWidget.boldTextFeildStyle().copyWith(
                        fontSize: 22,
                        color: _themeOrange,
                      ),
                    ),
                  ],
                ),
              ),

              // 🛒 CHECKOUT BUTTON
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20.0,
                  vertical: 20.0,
                ),
                child: ElevatedButton.icon(
                  onPressed: () async {
                    int walletAmount =
                        int.tryParse(
                          wallet?.replaceAll(RegExp(r'[^0-9]'), '') ?? "0",
                        ) ??
                            0;

                    if (walletAmount < total) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          backgroundColor: Colors.redAccent,
                          content: Text(
                            "❌ Not enough balance in wallet!",
                            style: TextStyle(fontSize: 16.0, color: Colors.white),
                          ),
                        ),
                      );
                      return;
                    }

                    int newBalance = walletAmount - total;

                    // Order processing logic (unchanged)
                    await DatabaseMethods().updateUserWallet(id!, newBalance.toString());
                    await SharedPreferenceHelper().saveUserWallet(newBalance.toString());

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        backgroundColor: Colors.green,
                        content: Text(
                          "✅ Order placed successfully!",
                          style: TextStyle(fontSize: 16.0, color: Colors.white),
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.shopping_bag, color: Colors.white),
                  label: const Text(
                    "Proceed to Checkout",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _themeOrange, // Branded Orange Button
                    minimumSize: const Size(double.infinity, 55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background for better contrast
      appBar: AppBar(
        // Themed AppBar
        backgroundColor: _themeOrange,
        elevation: 0,
        // The back button should navigate back in a typical scenario, but if the Cart is a main tab, this can be customized.
        leading: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
        title: Text("My Cart", style: AppWidget.semiBoldTextFeildStyle().copyWith(color: Colors.white, fontSize: 22)),
        centerTitle: true,
      ),
      body: foodCart(),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/widget/widget_support.dart';

class Details extends StatefulWidget {
  final String image, name, detail, price;
  const Details({
    super.key,
    required this.image,
    required this.name,
    required this.detail,
    required this.price,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  final Color _themeOrange = const Color(0xFFff5c30); // Theme color

  int quantity = 1;
  double total = 0.0;
  String? userId;

  @override
  void initState() {
    super.initState();
    _loadUserId();
    _calculateTotal();
  }

  Future<void> _loadUserId() async {
    userId = await SharedPreferenceHelper().getUserId();
    setState(() {});
  }

  void _calculateTotal() {
    double priceValue =
        double.tryParse(widget.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;
    total = quantity * priceValue;
  }

  Future<void> _addToCart() async {
    if (userId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("⚠️ Please log in to add items to your cart."),
        ),
      );
      return;
    }

    // Ensure price is parsed correctly before use
    final priceValue =
        double.tryParse(widget.price.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0.0;

    final cartItem = {
      "Name": widget.name,
      "Quantity": quantity,
      "PricePerUnit": priceValue,
      "Total": total,
      "Image": widget.image,
      "Timestamp": DateTime.now(),
    };

    try {
      await DatabaseMethods().addFoodToCart(cartItem, userId!);
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: _themeOrange, // Use theme color for success
          content: const Text("✅ Added to cart successfully!"),
          action: SnackBarAction(
            label: "🛒 View Cart",
            textColor: Colors.white,
            onPressed: () {
              // Navigate to the Order/Cart page
              Navigator.pushNamed(context, '/Order');
            },
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text("❌ Error adding to cart: $e"),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Recalculate price value for display
    final double priceValue =
        double.tryParse(widget.price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0;

    return Scaffold(
      backgroundColor: Colors.grey[50], // Lighter background
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Product Details",
          style: AppWidget.semiBoldTextFeildStyle(),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 🖼️ Product Image
            Container(
              height: 280, // Slightly taller image
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20), // More rounded
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15), // Darker shadow for depth
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Image.network(
                widget.image,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) =>
                    Center(child: Icon(Icons.broken_image, size: 80, color: Colors.grey)),
              ),
            ),
            const SizedBox(height: 25),

            // 🏷️ Product Info
            Text(
              widget.name,
              style: AppWidget.HeadlineTextFeildStyle().copyWith(fontSize: 26, color: Colors.black),
            ),
            const SizedBox(height: 10),
            Text(
              widget.detail,
              style: AppWidget.LightTextFeildStyle().copyWith(fontSize: 16, color: Colors.black87),
            ),
            const SizedBox(height: 25),

            // 💰 Price & Quantity Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Price Column
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Unit Price",
                        style: AppWidget.LightTextFeildStyle().copyWith(fontSize: 15, color: Colors.grey[600]),
                      ),
                      Text(
                        "₹${priceValue.toStringAsFixed(2)}",
                        style: AppWidget.boldTextFeildStyle().copyWith(
                          fontSize: 24,
                          color: _themeOrange, // Themed Price Color
                        ),
                      ),
                    ],
                  ),
                  // Quantity Buttons
                  Row(
                    children: [
                      _buildQuantityButton(Icons.remove, () {
                        if (quantity > 1) {
                          setState(() {
                            quantity--;
                            _calculateTotal();
                          });
                        }
                      }),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          "$quantity",
                          style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 20),
                        ),
                      ),
                      _buildQuantityButton(Icons.add, () {
                        setState(() {
                          quantity++;
                          _calculateTotal();
                        });
                      }),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 25),

            // 🧾 Summary Section
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Order Summary",
                    style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow("Product", widget.name),
                  _buildSummaryRow("Quantity", "$quantity pcs"),
                  _buildSummaryRow("Delivery Time", "30 mins"),
                  const Divider(thickness: 1.5, height: 25, color: Colors.grey),
                  _buildSummaryRow(
                    "Grand Total",
                    "₹${total.toStringAsFixed(2)}",
                    isBold: true,
                    color: _themeOrange, // Themed Total Color
                  ),
                ],
              ),
            ),

            const SizedBox(height: 35),

            // 🛒 Add to Cart Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _addToCart,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _themeOrange, // Themed Button Color
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15), // Consistent rounding
                      ),
                      elevation: 5,
                    ),
                    icon: const Icon(
                      Icons.add_shopping_cart, // Updated icon for visual appeal
                      color: Colors.white,
                    ),
                    label: Text(
                      "Add to Cart",
                      style: AppWidget.boldTextFeildStyle().copyWith(
                        fontSize: 18,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  // 🔹 Quantity Button Widget (Themed)
  Widget _buildQuantityButton(IconData icon, VoidCallback onPressed) {
    return InkWell(
      onTap: onPressed,
      child: Container(
        decoration: BoxDecoration(
          color: _themeOrange.withOpacity(0.1), // Light orange background
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _themeOrange.withOpacity(0.5)),
        ),
        padding: const EdgeInsets.all(8),
        child: Icon(icon, color: _themeOrange, size: 22), // Themed icon color
      ),
    );
  }

  // 🔹 Summary Row Widget (Themed)
  Widget _buildSummaryRow(String label, String value, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 15, color: Colors.black87),
          ),
          Text(
            value,
            style: AppWidget.semiBoldTextFeildStyle().copyWith(
              fontSize: 16,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
              color: color ?? Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}
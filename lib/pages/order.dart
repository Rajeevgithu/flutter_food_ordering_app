import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/widget/widget_support.dart';
import 'package:e_commerce_app/pages/details.dart'; // ✅ Make sure this import exists

class Order extends StatefulWidget {
  const Order({super.key});

  @override
  State<Order> createState() => _OrderState();
}

class _OrderState extends State<Order> {
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

  Widget foodCart() {
    return StreamBuilder(
      stream: foodStream,
      builder: (context, AsyncSnapshot snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        int total = 0;
        for (var doc in snapshot.data.docs) {
          final cleanTotal = doc["Total"].toString().replaceAll(
            RegExp(r'[^0-9]'),
            '',
          );
          total += int.tryParse(cleanTotal) ?? 0;
        }

        return Column(
          children: [
            // 🧾 CART LIST
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: snapshot.data.docs.length,
                itemBuilder: (context, index) {
                  DocumentSnapshot ds = snapshot.data.docs[index];
                  final cleanTotal = ds["Total"].toString().replaceAll(
                    RegExp(r'[^0-9]'),
                    '',
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: Colors.black12,
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
                                    const Icon(Icons.broken_image, size: 60),
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
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "₹${ds["PricePerUnit"]} x ${ds["Quantity"]}",
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "₹$cleanTotal",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.orange,
                                  ),
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
                              Icons.delete_forever,
                              color: Colors.redAccent,
                              size: 28,
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
              margin: const EdgeInsets.symmetric(
                horizontal: 20.0,
                vertical: 8.0,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Total Amount",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    "₹$total",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

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

                  await DatabaseMethods().updateUserWallet(
                    id!,
                    newBalance.toString(),
                  );
                  await SharedPreferenceHelper().saveUserWallet(
                    newBalance.toString(),
                  );

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
                icon: const Icon(Icons.payment, color: Colors.white),
                label: const Text(
                  "Proceed to Checkout",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text("My Cart", style: AppWidget.semiBoldTextFeildStyle()),
        centerTitle: true,
      ),
      body: foodCart(),
    );
  }
}

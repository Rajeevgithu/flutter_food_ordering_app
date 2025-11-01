import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/pages/details.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/widget/widget_support.dart';
import 'package:flutter/material.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  bool drinks = true, icecream = false, fast_food = false, milk = false;
  String selectedCategory = "drinks";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Container(
          margin: const EdgeInsets.only(top: 50, left: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  FutureBuilder<String?>(
                    future: SharedPreferenceHelper().getUserName(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Text(
                          "Hello...",
                          style: AppWidget.boldTextFeildStyle(),
                        );
                      } else if (snapshot.hasError) {
                        return Text(
                          "Hello User",
                          style: AppWidget.boldTextFeildStyle(),
                        );
                      } else {
                        final name = snapshot.data ?? "User";
                        return Text(
                          "Hello $name,",
                          style: AppWidget.boldTextFeildStyle(),
                        );
                      }
                    },
                  ),
                  Container(
                    margin: const EdgeInsets.only(right: 20),
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.shopping_cart, color: Colors.white),
                  ),
                ],
              ),

              const SizedBox(height: 30),
              Text("Delicious Food", style: AppWidget.HeadlineTextFeildStyle()),
              Text(
                "Discover and Get Great Food",
                style: AppWidget.LightTextFeildStyle(),
              ),

              const SizedBox(height: 20),
              // --- Categories ---
              Container(
                margin: const EdgeInsets.only(right: 20),
                child: showItem(),
              ),
              const SizedBox(height: 30),

              // --- Food list from Firestore ---
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection("foods")
                    .where("Category", isEqualTo: selectedCategory)
                    .snapshots(),

                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  var items = snapshot.data!.docs;

                  if (items.isEmpty) {
                    return const Center(
                      child: Text("No items available in this category"),
                    );
                  }

                  return Column(
                    children: [
                      SizedBox(
                        height: 300,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: items.length,
                          itemBuilder: (context, index) {
                            var data = items[index];
                            return productCard(data);
                          },
                        ),
                      ),
                      ListView.builder(
                        itemCount: items.length,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (context, index) {
                          var data = items[index];
                          return productRow(data);
                        },
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Product Horizontal Card ---
  Widget productCard(QueryDocumentSnapshot data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(
              detail: data["Detail"],
              image: data["Image"],
              name: data["Name"],
              price: data["Price"].toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.all(8),
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(14),
            width: 170,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    data["Image"], // ✅ Cloudinary image URL
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    loadingBuilder: (context, child, progress) {
                      if (progress == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  data["Name"],
                  style: AppWidget.semiBoldTextFeildStyle(),
                  textAlign: TextAlign.center,
                ),
                Text(
                  "Fresh & Healthy",
                  style: AppWidget.LightTextFeildStyle(),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  "₹${data["Price"]}",
                  style: AppWidget.semiBoldTextFeildStyle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Product Vertical Row ---
  Widget productRow(QueryDocumentSnapshot data) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => Details(
              detail: data["Detail"],
              image: data["Image"],
              name: data["Name"],
              price: data["Price"].toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(right: 20, bottom: 20),
        child: Material(
          elevation: 5,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.network(
                    data["Image"],
                    height: 120,
                    width: 120,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["Name"],
                        style: AppWidget.semiBoldTextFeildStyle(),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data["Detail"],
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppWidget.LightTextFeildStyle(),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        "₹${data["Price"]}",
                        style: AppWidget.semiBoldTextFeildStyle(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // --- Category buttons ---
  Widget showItem() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        categoryButton("drinks", "images/drinks/drinks.png", drinks),
        categoryButton("Ice-cream", "images/ice-cream/ice-cream.png", icecream),
        categoryButton(
          "fast_food",
          "images/fast_food/fast-food.png",
          fast_food,
        ),
        categoryButton("milk", "images/milk_food/milk.png", milk),
      ],
    );
  }

  Widget categoryButton(String name, String imagePath, bool selected) {
    return GestureDetector(
      onTap: () {
        setState(() {
          drinks = name == "drinks";
          icecream = name == "Ice-cream";
          fast_food = name == "fast_food";
          milk = name == "milk";
          selectedCategory = name;
        });
      },
      child: Material(
        elevation: 5,
        borderRadius: BorderRadius.circular(15),
        child: Container(
          height: 70,
          width: 70,
          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.white,
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.all(10),
          child: Image.asset(
            imagePath,
            fit: BoxFit.contain,
            color: selected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }
}

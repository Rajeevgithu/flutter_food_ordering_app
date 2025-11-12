import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/pages/details.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:e_commerce_app/widget/widget_support.dart';
import 'package:flutter/material.dart';

import 'bottomnav.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final Color _themeOrange = const Color(0xFFff5c30);
  final TextEditingController _searchController = TextEditingController();

  bool drinks = true, icecream = false, fast_food = false, milk = false;
  String selectedCategory = "drinks";
  String searchQuery = "";

  // --- Filter State Variables ---
  String selectedDeliveryTime = '10min';
  RangeValues priceRange = const RangeValues(0, 1000); // 🎯 UPDATED MAX PRICE TO 1000
  int selectedRating = 5;
  List<String> selectedTags = [];

  final List<String> availableTags = [
    'Drinks', 'Milk', 'Ice-Cream', 'Fast Food',
  ];

  // New method to handle category selection state
  void selectCategory(String category) {
    setState(() {
      drinks = category == "drinks";
      icecream = category == "Ice-cream";
      fast_food = category == "fast_food";
      milk = category == "milk";
      selectedCategory = category;
      searchQuery = ""; // Clear search when category changes
      _searchController.clear();
      // Reset filters when category changes, or keep them if intended to apply universally
      // For now, let's keep the filter state, but it only applies if search is active.
    });
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // --- Filter UI Implementation ---
  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        String tempSelectedTime = selectedDeliveryTime;
        RangeValues tempPriceRange = priceRange;
        int tempSelectedRating = selectedRating;
        List<String> tempSelectedTags = List.from(selectedTags);

        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setStateModal) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
              ),
              child: Column(
                children: [
                  // Header and Close Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Filter your search", style: AppWidget.HeadlineTextFeildStyle().copyWith(fontSize: 22)),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),

                  // Filter Content
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 10),

                          // --- Delivery Time ---
                          Text("Delivery time", style: AppWidget.semiBoldTextFeildStyle()),
                          const SizedBox(height: 10),
                          Row(
                            children: ['10min', '15min', '20min']
                                .map((time) => _buildTimeChip(time, tempSelectedTime, setStateModal, (val) => tempSelectedTime = val))
                                .toList(),
                          ),
                          const SizedBox(height: 30),

                          // --- Price Range ---
                          Text("Price Range", style: AppWidget.semiBoldTextFeildStyle()),
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: _themeOrange,
                              inactiveTrackColor: Colors.grey[300],
                              thumbColor: _themeOrange,
                              overlayColor: _themeOrange.withOpacity(0.2),
                              trackHeight: 6.0,
                              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10.0),
                              rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10.0),
                            ),
                            child: RangeSlider(
                              values: tempPriceRange,
                              min: 0,
                              max: 1000, // 🎯 UPDATED MAX SLIDER VALUE
                              divisions: 100,
                              labels: RangeLabels(
                                '₹${tempPriceRange.start.round()}',
                                '₹${tempPriceRange.end.round()}',
                              ),
                              onChanged: (RangeValues newValues) {
                                setStateModal(() {
                                  tempPriceRange = newValues;
                                });
                              },
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('₹${tempPriceRange.start.round()}', style: AppWidget.LightTextFeildStyle()),
                                Text('₹${tempPriceRange.end.round()}', style: AppWidget.LightTextFeildStyle()),
                              ],
                            ),
                          ),
                          const SizedBox(height: 30),

                          // --- Rating ---
                          Text("Rating", style: AppWidget.semiBoldTextFeildStyle()),
                          const SizedBox(height: 10),
                          Row(
                            children: [5, 4, 3, 2, 1]
                                .map((rating) => _buildRatingChip(rating, tempSelectedRating, setStateModal, (val) => tempSelectedRating = val))
                                .toList(),
                          ),
                          const SizedBox(height: 30),

                          // --- Tags (Categories) ---
                          Text("Tags", style: AppWidget.semiBoldTextFeildStyle()),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8.0,
                            runSpacing: 8.0,
                            children: availableTags
                                .map((tag) => _buildTagChip(tag, tempSelectedTags, setStateModal, (val) {
                              if (tempSelectedTags.contains(val)) {
                                tempSelectedTags.remove(val);
                              } else {
                                tempSelectedTags.add(val);
                              }
                            }))
                                .toList(),
                          ),
                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),

                  // --- Apply Button ---
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        selectedDeliveryTime = tempSelectedTime;
                        priceRange = tempPriceRange;
                        selectedRating = tempSelectedRating;
                        selectedTags = tempSelectedTags;
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _themeOrange,
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: const Center(
                        child: Text(
                          "Apply Filter",
                          style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // --- Helper Widgets for Filter Sheet (no functional changes) ---
  Widget _buildTimeChip(String time, String selectedTime, StateSetter setStateModal, Function(String) onSelect) {
    bool isSelected = time == selectedTime;
    return GestureDetector(
      onTap: () {
        setStateModal(() {
          onSelect(time);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? _themeOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          time,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRatingChip(int rating, int selectedRating, StateSetter setStateModal, Function(int) onSelect) {
    bool isSelected = rating == selectedRating;
    return GestureDetector(
      onTap: () {
        setStateModal(() {
          onSelect(rating);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        margin: const EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: isSelected ? _themeOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Text(
              rating.toString(),
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.black,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            Icon(Icons.star, size: 16, color: isSelected ? Colors.white : Colors.amber),
          ],
        ),
      ),
    );
  }

  Widget _buildTagChip(String tag, List<String> selectedTags, StateSetter setStateModal, Function(String) onToggle) {
    bool isSelected = selectedTags.contains(tag);
    return GestureDetector(
      onTap: () {
        setStateModal(() {
          onToggle(tag);
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? _themeOrange : Colors.grey[200],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          tag,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black,
          ),
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    // Ensure _themeOrange is accessible here (it's defined in _HomeState)
    final Color _themeOrange = const Color(0xFFff5c30);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- 1. Top AppBar Section (Gradient Background) ---
            Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [_themeOrange, const Color(0xFFe74b1a)],
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header Row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Welcome Text
                      FutureBuilder<String?>(
                        future: SharedPreferenceHelper().getUserName(),
                        builder: (context, snapshot) {
                          final name = snapshot.data ?? "User";
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Welcome Back,",
                                style: AppWidget.semiBoldTextFeildStyle().copyWith(color: Colors.white70),
                              ),
                              Text(
                                name,
                                style: AppWidget.boldTextFeildStyle().copyWith(fontSize: 24, color: Colors.white),
                              ),
                            ],
                          );
                        },
                      ),

                      // Cart Icon 🎯 NAVIGATION ADDED HERE
                      GestureDetector(
                        onTap: () {
                          // Navigate to BottomNav and set the starting index to the Cart page (Index 1)
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              // Ensure BottomNav is imported and updated with the initialIndex property
                              builder: (context) => BottomNav(initialIndex: 1),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.shopping_cart, color: Colors.white, size: 24),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 30),

                  // Search Bar with Filter Button
                  Row(
                    children: [
                      // Search Field
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              hintText: "Search for food...",
                              hintStyle: AppWidget.LightTextFeildStyle(),
                              border: InputBorder.none,
                              prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                            ),
                            style: AppWidget.semiBoldTextFeildStyle(),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      // Filter Button
                      GestureDetector(
                        onTap: () => _showFilterSheet(context),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Icon(Icons.filter_list, color: _themeOrange, size: 24),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- 2. Main Content Area ---
            Padding(
              padding: const EdgeInsets.only(top: 20.0, left: 20.0, right: 20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // --- Categories ---
                  Text("Quick Categories", style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18)),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 90,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        categoryButton("drinks", "images/drinks/drinks.png", drinks),
                        const SizedBox(width: 10),
                        categoryButton("Ice-cream", "images/ice-cream/ice-cream.png", icecream),
                        const SizedBox(width: 10),
                        categoryButton(
                          "fast_food",
                          "images/fast_food/fast-food.png",
                          fast_food,
                        ),
                        const SizedBox(width: 10),
                        categoryButton("milk", "images/milk_food/milk.png", milk),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  // --- Food list from Firestore (QUERIES ALL FOODS) ---
                  StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance.collection("foods").snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Center(child: CircularProgressIndicator(color: _themeOrange));
                      }
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.only(top: 40),
                            child: Text("No items available.", style: TextStyle(fontSize: 16, color: Colors.black54)),
                          ),
                        );
                      }

                      var allItems = snapshot.data!.docs;

                      // 🎯 Universal Search / Category / Filter Logic
                      var filteredItems = allItems.where((doc) {
                        var name = (doc["Name"] as String).toLowerCase();
                        var category = (doc["Category"] as String).toLowerCase();
                        var price = double.tryParse(doc["Price"] as String? ?? '0') ?? 0.0;

                        // 1. Price Range Filter
                        bool matchesPrice = price >= priceRange.start && price <= priceRange.end;

                        // --- UNIVERSAL SEARCH LOGIC ---
                        if (searchQuery.isNotEmpty) {
                          // If search is active, ignore the category chip but apply price/tag filters
                          bool matchesSearch = name.contains(searchQuery);
                          // Add Tag filter logic here if needed, but for simple search, just use name/price
                          return matchesSearch && matchesPrice;
                        }
                        // --- CATEGORY FILTER LOGIC (When search is empty) ---
                        else {
                          // If search is empty, filter by the active category chip and price range
                          bool matchesCategory = category == selectedCategory.toLowerCase();
                          return matchesCategory && matchesPrice;
                        }

                      }).toList();

                      if (filteredItems.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 40),
                            child: Text("No results found for current filters/search.", style: AppWidget.LightTextFeildStyle()),
                          ),
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Horizontal Scroll (Featured Cards)
                          Text("Popular Picks", style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18)),
                          const SizedBox(height: 10),
                          SizedBox(
                            height: 250,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: filteredItems.length,
                              itemBuilder: (context, index) {
                                return productCard(filteredItems[index]);
                              },
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Vertical List (Detailed Rows)
                          Text("All Items", style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 18)),
                          const SizedBox(height: 10),
                          ListView.builder(
                            itemCount: filteredItems.length,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              return productRow(filteredItems[index]);
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Product Cards and Rows (Price casting fix is assumed to be applied here) ---

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
        width: 180,
        margin: const EdgeInsets.only(right: 15),
        child: Material(
          elevation: 8,
          shadowColor: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
            decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade100)
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      data["Image"],
                      height: 120,
                      width: 150,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 120,
                          width: 150,
                          child: Center(child: CircularProgressIndicator(color: _themeOrange.withOpacity(0.7))),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.broken_image, size: 50, color: Colors.redAccent),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  data["Name"],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 16),
                ),
                Text(
                  "Fresh & Healthy",
                  style: AppWidget.LightTextFeildStyle().copyWith(color: Colors.grey[600]),

                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "₹${data["Price"] as String}", // Price display fix
                      style: AppWidget.semiBoldTextFeildStyle().copyWith(color: _themeOrange, fontSize: 18),
                    ),
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: _themeOrange,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.add, color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

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
        margin: const EdgeInsets.only(bottom: 15),
        child: Material(
          elevation: 5,
          shadowColor: Colors.black.withOpacity(0.1),
          borderRadius: BorderRadius.circular(15),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    data["Image"],
                    height: 90,
                    width: 90,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.broken_image, size: 50, color: Colors.redAccent),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data["Name"],
                        style: AppWidget.semiBoldTextFeildStyle().copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        data["Detail"],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppWidget.LightTextFeildStyle().copyWith(color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "₹${data["Price"] as String}", // Price display fix
                        style: AppWidget.semiBoldTextFeildStyle().copyWith(color: _themeOrange, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: _themeOrange,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add, color: Colors.white, size: 22),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget categoryButton(String name, String imagePath, bool selected) {
    return GestureDetector(
      onTap: () => selectCategory(name),
      child: Column(
        children: [
          Material(
            elevation: selected ? 8 : 2,
            shadowColor: selected ? _themeOrange.withOpacity(0.4) : Colors.black.withOpacity(0.1),
            borderRadius: BorderRadius.circular(15),
            child: Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: selected ? _themeOrange : Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              padding: const EdgeInsets.all(7),
              child: Image.asset(
                imagePath,
                fit: BoxFit.contain,
                color: selected ? Colors.white : Colors.black54,
              ),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            name.replaceAll('_', ' ').toUpperCase(),
            style: AppWidget.LightTextFeildStyle().copyWith(
              fontSize: 12,
              color: selected ? _themeOrange : Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
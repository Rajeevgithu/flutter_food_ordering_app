import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class DatabaseMethods {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// 🧩 Add user details during signup
  Future<void> addUserDetail(
    Map<String, dynamic> userInfoMap,
    String userId,
  ) async {
    try {
      userInfoMap["role"] ??= "user"; // ✅ Default role
      await _firestore
          .collection("user")
          .doc(userId)
          .set(userInfoMap, SetOptions(merge: true));
      debugPrint("✅ User data successfully saved for ID: $userId");
    } catch (e) {
      debugPrint("❌ Failed to add user data: $e");
      rethrow;
    }
  }

  /// 👤 Get user details by userId
  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDetail(
    String userId,
  ) async {
    try {
      final doc = await _firestore.collection("user").doc(userId).get();
      if (doc.exists) {
        debugPrint("✅ User details fetched for ID: $userId");
      } else {
        debugPrint("⚠️ No user found for ID: $userId");
      }
      return doc;
    } catch (e) {
      debugPrint("❌ Failed to fetch user details for $userId: $e");
      rethrow;
    }
  }

  /// 💰 Update user's wallet amount
  Future<void> updateUserWallet(String userId, String newAmount) async {
    try {
      if (userId.isEmpty) throw Exception("User ID cannot be empty");
      await _firestore.collection("user").doc(userId).update({
        "wallet": newAmount,
      });
      debugPrint("✅ Wallet updated for user: $userId → Amount: $newAmount");
    } catch (e) {
      debugPrint("❌ Failed to update wallet for $userId: $e");
      rethrow;
    }
  }

  /// 🍔 Add a food item (admin functionality)
  Future<void> addFoodItem(
    Map<String, dynamic> foodInfoMap,
    String category,
  ) async {
    try {
      await _firestore.collection("foods").add(foodInfoMap);
      debugPrint("✅ Food item added successfully under category: $category");
    } catch (e) {
      debugPrint("❌ Failed to add food item: $e");
      rethrow;
    }
  }

  /// 📦 Get all food items for a specific category
  Stream<QuerySnapshot<Map<String, dynamic>>> getFoodItem(String category) {
    try {
      return _firestore
          .collection("foods")
          .where("category", isEqualTo: category)
          .snapshots();
    } catch (e) {
      debugPrint("❌ Failed to fetch food items for category $category: $e");
      rethrow;
    }
  }

  /// 🛒 Add an item to a user's cart
  Future<void> addFoodToCart(
    Map<String, dynamic> cartItem,
    String userId,
  ) async {
    try {
      if (userId.isEmpty) throw Exception("User ID cannot be empty");
      await _firestore
          .collection("user")
          .doc(userId)
          .collection("cart")
          .add(cartItem);
      debugPrint("✅ Cart item added successfully for user: $userId");
    } catch (e) {
      debugPrint("❌ Failed to add item to cart for $userId: $e");
      rethrow;
    }
  }

  /// 🧾 Get all items in a user's cart (real-time updates)
  Stream<QuerySnapshot<Map<String, dynamic>>> getFoodCart(String userId) {
    try {
      if (userId.isEmpty) throw Exception("User ID cannot be empty");
      return _firestore
          .collection("user")
          .doc(userId)
          .collection("cart")
          .snapshots();
    } catch (e) {
      debugPrint("❌ Failed to retrieve cart items for $userId: $e");
      rethrow;
    }
  }

  /// 📋 Get all food items (for admin dashboard or search)
  Stream<QuerySnapshot<Map<String, dynamic>>> getAllFoods() {
    try {
      return _firestore.collection("foods").snapshots();
    } catch (e) {
      debugPrint("❌ Failed to fetch all foods: $e");
      rethrow;
    }
  }

  /// ❌ Delete a food item (admin only)
  Future<void> deleteFood(String docId) async {
    try {
      await _firestore.collection("foods").doc(docId).delete();
      debugPrint("✅ Deleted food item: $docId");
    } catch (e) {
      debugPrint("❌ Failed to delete food item ($docId): $e");
      rethrow;
    }
  }

  /// 👤 Get user detail by email
  Future<DocumentSnapshot<Map<String, dynamic>>?> getUserByEmail(
    String email,
  ) async {
    try {
      final query = await _firestore
          .collection("user")
          .where("email", isEqualTo: email)
          .get();

      if (query.docs.isNotEmpty) {
        debugPrint("✅ User found for email: $email");
        return query.docs.first;
      } else {
        debugPrint("⚠️ No user found with email: $email");
        return null;
      }
    } catch (e) {
      debugPrint("❌ Error while fetching user by email: $e");
      return null;
    }
  }
}

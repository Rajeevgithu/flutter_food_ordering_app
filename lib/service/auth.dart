import 'package:firebase_auth/firebase_auth.dart';

class AuthMethods {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// 🔹 Get the current signed-in Firebase user
  Future<User?> getCurrentUser() async {
    return _auth.currentUser;
  }

  /// 🔹 Sign out the current user
  Future<void> signOut() async {
    try {
      await _auth.signOut();
      print("✅ User signed out successfully");
    } catch (e) {
      print("❌ Error signing out: $e");
      rethrow;
    }
  }

  /// 🔹 Delete the current user (with safe handling)
  Future<void> deleteUser() async {
    try {
      User? user = _auth.currentUser;

      if (user != null) {
        await user.delete();
        print("✅ User deleted successfully");
      } else {
        print("⚠️ No user currently signed in");
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        print("⚠️ User must reauthenticate before deletion");
        rethrow; // let UI handle this with a message
      } else {
        print("❌ FirebaseAuth error: ${e.message}");
        rethrow;
      }
    } catch (e) {
      print("❌ Unknown error deleting user: $e");
      rethrow;
    }
  }

  /// 🔹 Create a new user with email and password
  Future<User?> registerWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("✅ Registered user: ${result.user?.uid}");
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Registration failed: ${e.message}");
      rethrow;
    }
  }

  /// 🔹 Login existing user
  Future<User?> signInWithEmailPassword(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      print("✅ Signed in user: ${result.user?.uid}");
      return result.user;
    } on FirebaseAuthException catch (e) {
      print("❌ Login failed: ${e.message}");
      rethrow;
    }
  }

  /// 🔹 Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      print("📧 Password reset email sent to $email");
    } catch (e) {
      print("❌ Failed to send password reset email: $e");
      rethrow;
    }
  }
}

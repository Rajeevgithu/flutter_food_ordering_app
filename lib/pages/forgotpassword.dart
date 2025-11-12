import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/pages/signup.dart';
// Assuming widget_support contains your AppWidget styles
import 'package:e_commerce_app/widget/widget_support.dart';

class ForgotPassword extends StatefulWidget {
  const ForgotPassword({super.key});

  @override
  State<ForgotPassword> createState() => _ForgotPasswordState();
}

class _ForgotPasswordState extends State<ForgotPassword> {
  final Color _themeOrange = const Color(0xFFff5c30); // Theme color
  final TextEditingController mailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    mailController.dispose();
    super.dispose();
  }

  Future<void> resetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(
        email: mailController.text.trim(),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.green,
          content: Text(
            "✅ Password reset email sent! Check your inbox.",
            style: TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ),
      );

      // Redirect to Login screen after a short delay
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) {
          Navigator.pop(context);
        }
      });
    } on FirebaseAuthException catch (e) {
      String message = "An unknown error occurred.";

      if (e.code == "user-not-found") {
        message = "No account found for this email.";
      } else if (e.code == "invalid-email") {
        message = "The email address is badly formatted.";
      } else if (e.code == "too-many-requests") {
        message = "Too many failed attempts. Try again later.";
      } else {
        message = "Error: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "❌ $message",
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background maintained
      body: SingleChildScrollView(
        child: SafeArea(
          child: Column(
            children: [
              // --- 1. Top Bar/Back Button ---
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),

              const SizedBox(height: 10.0),

              // --- 2. Header Text ---
              Text(
                "Password Recovery",
                style: AppWidget.HeadlineTextFeildStyle().copyWith(
                  color: Colors.white,
                  fontSize: 30.0,
                ),
              ),
              const SizedBox(height: 8.0),
              Text(
                "Enter your registered email to receive the link.",
                style: AppWidget.LightTextFeildStyle().copyWith(
                  color: Colors.white70,
                  fontSize: 16.0,
                ),
              ),
              const SizedBox(height: 50.0),

              // --- 3. Form Section ---
              Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 25.0),
                  child: Column(
                    children: [
                      // --- Email Input Field ---
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10.0),
                        decoration: BoxDecoration(
                          // Border color using theme orange for accent
                          border: Border.all(color: _themeOrange.withOpacity(0.8), width: 2.0),
                          borderRadius: BorderRadius.circular(15), // Smoother corners
                        ),
                        child: TextFormField(
                          controller: mailController,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your email address.';
                            }
                            final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                            if (!emailRegex.hasMatch(value)) {
                              return 'Enter a valid email address.';
                            }
                            return null;
                          },
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Email Address",
                            hintStyle: AppWidget.LightTextFeildStyle().copyWith(
                              fontSize: 18.0,
                              color: Colors.white54,
                            ),
                            prefixIcon: Icon(
                              Icons.email_outlined,
                              color: _themeOrange, // Themed icon
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 40.0),

                      // --- Send Reset Email Button ---
                      GestureDetector(
                        onTap: _isLoading ? null : resetPassword,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          decoration: BoxDecoration(
                            color: _themeOrange, // Themed button color
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Center(
                            child: _isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : Text(
                              "Send Reset Email",
                              style: AppWidget.boldTextFeildStyle().copyWith(
                                color: Colors.white,
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 60.0),

                      // --- Signup Link ---
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account?",
                            style: AppWidget.LightTextFeildStyle().copyWith(
                              fontSize: 16.0,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 5.0),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const SignUp(),
                                ),
                              );
                            },
                            child: Text(
                              "Create One",
                              style: AppWidget.semiBoldTextFeildStyle().copyWith(
                                color: _themeOrange, // Themed link color
                                fontSize: 18.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20.0),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
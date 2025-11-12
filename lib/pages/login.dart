import 'package:e_commerce_app/admin/home_admin.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/service/shared_pref.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/pages/bottomnav.dart';
import 'package:e_commerce_app/pages/forgotpassword.dart';
import 'package:e_commerce_app/pages/signup.dart';
import 'package:e_commerce_app/widget/widget_support.dart';

class LogIn extends StatefulWidget {
  const LogIn({super.key});

  @override
  State<LogIn> createState() => _LogInState();
}

class _LogInState extends State<LogIn> {
  String email = "", password = "";

  final _formkey = GlobalKey<FormState>();

  TextEditingController useremailcontroller = TextEditingController();
  TextEditingController userpasswordcontroller = TextEditingController();

  userLogin() async {
    try {
      // ✅ Firebase sign-in
      UserCredential userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);

      User? user = userCredential.user;

      if (user != null) {
        String id = user.uid;

        // ✅ Fetch user info from Firestore (now uses "user" collection)
        var userInfo = await DatabaseMethods().getUserDetail(id);

        if (userInfo.exists) {
          var data = userInfo.data() as Map<String, dynamic>;
          String role = data["role"] ?? "user"; // default fallback

          // ✅ Save in SharedPreferences
          await SharedPreferenceHelper().saveUserId(id);
          await SharedPreferenceHelper().saveUserEmail(email);
          await SharedPreferenceHelper().saveUserName(data["Name"] ?? "");
          await SharedPreferenceHelper().saveUserWallet(data["Wallet"] ?? "0");
          await SharedPreferenceHelper().saveUserRole(role);

          print("✅ User logged in successfully: $role");

          // ✅ Navigate based on role
          if (role == "admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const HomeAdmin()),
            );
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const BottomNav()),
            );
          }
        } else {
          throw Exception("User document not found in Firestore.");
        }
      }
    } on FirebaseAuthException catch (e) {
      String message = "";
      if (e.code == 'user-not-found') {
        message = "No user found for that email.";
      } else if (e.code == 'wrong-password') {
        message = "Wrong password provided.";
      } else {
        message = "Login failed: ${e.message}";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            message,
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: Colors.redAccent,
          content: Text(
            "Error: $e",
            style: const TextStyle(fontSize: 16.0, color: Colors.white),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // ✅ Ensures layout adjusts when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ Allows scrolling to prevent overflow
          child: Container(
            height: MediaQuery.of(context).size.height,
            child: Stack(
              children: [
                // 🔸 Background Gradient
                Container(
                  width: MediaQuery.of(context).size.width,
                  height: MediaQuery.of(context).size.height / 2.5,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFff5c30), Color(0xFFe74b1a)],
                    ),
                  ),
                ),

                // 🔸 White bottom container
                Container(
                  margin: EdgeInsets.only(
                    top: MediaQuery.of(context).size.height / 3,
                  ),
                  height: MediaQuery.of(context).size.height / 1.6,
                  width: MediaQuery.of(context).size.width,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),

                // 🔸 Content section
                Container(
                  margin: EdgeInsets.only(top: 60.0, left: 20.0, right: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          "images/logo.png",
                          width: MediaQuery.of(context).size.width / 1.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(height: 40.0),

                      // 🔸 Login form card
                      Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 20.0,
                          ),
                          width: MediaQuery.of(context).size.width,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Form(
                            key: _formkey,
                            child: Column(
                              children: [
                                Text(
                                  "Login",
                                  style: AppWidget.HeadlineTextFeildStyle(),
                                ),
                                SizedBox(height: 25.0),

                                // 🔹 Email
                                TextFormField(
                                  controller: useremailcontroller,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Email';
                                    }
                                    return null;
                                  },
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle:
                                        AppWidget.semiBoldTextFeildStyle(),
                                    prefixIcon: Icon(Icons.email_outlined),
                                  ),
                                ),
                                SizedBox(height: 25.0),

                                // 🔹 Password
                                TextFormField(
                                  controller: userpasswordcontroller,
                                  validator: (value) {
                                    if (value == null || value.isEmpty) {
                                      return 'Please Enter Password';
                                    }
                                    return null;
                                  },
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle:
                                        AppWidget.semiBoldTextFeildStyle(),
                                    prefixIcon: Icon(Icons.password_outlined),
                                  ),
                                ),
                                SizedBox(height: 15.0),

                                // 🔹 Forgot Password
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => ForgotPassword(),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    alignment: Alignment.topRight,
                                    child: Text(
                                      "Forgot Password?",
                                      style: AppWidget.semiBoldTextFeildStyle(),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 40.0),

                                // 🔹 Login Button
                                GestureDetector(
                                  onTap: () {
                                    if (_formkey.currentState!.validate()) {
                                      setState(() {
                                        email = useremailcontroller.text;
                                        password = userpasswordcontroller.text;
                                      });
                                      userLogin();
                                    }
                                  },
                                  child: Material(
                                    elevation: 5.0,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      width: 200,
                                      decoration: BoxDecoration(
                                        color: Color(0Xffff5722),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Center(
                                        child: Text(
                                          "LOGIN",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 18.0,
                                            fontFamily: 'Poppins1',
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 30.0),

                      // 🔸 Signup link
                      Padding(
                        padding: const EdgeInsets.only(bottom: 20.0),
                        child: GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SignUp()),
                            );
                          },
                          child: RichText(

                              text: TextSpan(
                                children: [
                                TextSpan(
                                text: "Don't have an account? ",
                                style: AppWidget.semiBoldTextFeildStyle().copyWith(
                                  // 🎯 Setting the base text color to black
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: "Sign up",
                                style: AppWidget.semiBoldTextFeildStyle().copyWith(
                                  // 🍊 Setting the 'Sign up' text color to orange
                                  color: const Color(0Xffff5722),

                            ),
                              )

                            ],
                          ),
                        ),
                        ),
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
}

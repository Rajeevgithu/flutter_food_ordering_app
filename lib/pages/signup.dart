// ignore: file_names
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:e_commerce_app/service/database.dart';
import 'package:e_commerce_app/widget/widget_support.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:e_commerce_app/pages/bottomnav.dart';
import 'package:e_commerce_app/pages/login.dart';
import 'package:e_commerce_app/service/shared_pref.dart';

class SignUp extends StatefulWidget {
  const SignUp({super.key});

  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  String email = "", password = "", name = "";
  final _formkey = GlobalKey<FormState>();

  TextEditingController namecontroller = TextEditingController();
  TextEditingController passwordcontroller = TextEditingController();
  TextEditingController mailcontroller = TextEditingController();

  /// ✅ Handle registration
  registration() async {
    if (password.isNotEmpty) {
      try {
        UserCredential userCredential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        User? user = userCredential.user;
        if (user == null) {
          throw FirebaseAuthException(
            code: 'user-creation-failed',
            message: 'User creation failed. Please try again.',
          );
        }

        String id = user.uid;

        // ✅ Create user document
        Map<String, dynamic> userInfo = {
          "Name": namecontroller.text,
          "Email": mailcontroller.text,
          "Wallet": "0",
          "Id": id,
          "Profile": "", // no image now
          "role": "user",
          "CreatedAt": FieldValue.serverTimestamp(),
        };

        await DatabaseMethods().addUserDetail(userInfo, id);

        // ✅ Save locally to SharedPreferences
        await SharedPreferenceHelper().saveUserName(namecontroller.text);
        await SharedPreferenceHelper().saveUserEmail(mailcontroller.text);
        await SharedPreferenceHelper().saveUserWallet('0');
        await SharedPreferenceHelper().saveUserId(id);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: Colors.greenAccent,
            content: Text(
              "Registered Successfully",
              style: TextStyle(fontSize: 18.0),
            ),
          ),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const BottomNav()),
        );
      } on FirebaseAuthException catch (e) {
        String errorMessage = "Registration failed";

        if (e.code == 'weak-password') {
          errorMessage = "Password is too weak";
        } else if (e.code == "email-already-in-use") {
          errorMessage = "Account already exists";
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orangeAccent,
            content: Text(errorMessage, style: const TextStyle(fontSize: 18.0)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            content: Text("Error: $e", style: const TextStyle(fontSize: 16.0)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      resizeToAvoidBottomInset:
      true, // ✅ Ensures layout adjusts when keyboard appears
      body: SafeArea(
        child: SingleChildScrollView(
          // ✅ Allows scrolling to prevent overflow
          child: Container(
            // Removed fixed height here to let SingleChildScrollView manage it
            // child: Stack now handles visual layout
            child: Stack(
              children: [
                // 🔸 1. Background Gradient (Top Half)
                Container(
                  width: size.width,
                  height: size.height / 2.5,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFff5c30), Color(0xFFe74b1a)],
                    ),
                  ),
                ),

                // 🔸 2. White bottom container (Rounded Corners)
                Container(
                  margin: EdgeInsets.only(
                    top: size.height / 3,
                  ),
                  height: size.height / 1.6, // Gives it enough height
                  width: size.width,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                ),

                // 🔸 3. Content section (Logo, Card, Link)
                Container(
                  margin: const EdgeInsets.only(
                      top: 60.0, left: 20.0, right: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Center(
                        child: Image.asset(
                          "images/logo.png",
                          width: size.width / 1.5,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 40.0),

                      // 🔸 Signup form card
                      Material(
                        elevation: 5.0,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20.0,
                            vertical: 20.0,
                          ),
                          width: size.width,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Form(
                            key: _formkey,
                            child: Column(
                              children: [
                                Text(
                                  "Sign Up",
                                  style: AppWidget.HeadlineTextFeildStyle(),
                                ),
                                const SizedBox(height: 25.0),

                                // 🔹 Name
                                TextFormField(
                                  controller: namecontroller,
                                  validator: (value) =>
                                  value!.isEmpty ? 'Please Enter Name' : null,
                                  decoration: InputDecoration(
                                    hintText: 'Name',
                                    hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                    prefixIcon: const Icon(Icons.person_outline),
                                  ),
                                ),
                                const SizedBox(height: 25.0),

                                // 🔹 Email
                                TextFormField(
                                  controller: mailcontroller,
                                  validator: (value) =>
                                  value!.isEmpty ? 'Please Enter Email' : null,
                                  decoration: InputDecoration(
                                    hintText: 'Email',
                                    hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                    prefixIcon: const Icon(Icons.email_outlined),
                                  ),
                                ),
                                const SizedBox(height: 25.0),

                                // 🔹 Password
                                TextFormField(
                                  controller: passwordcontroller,
                                  validator: (value) =>
                                  value!.isEmpty ? 'Please Enter Password' : null,
                                  obscureText: true,
                                  decoration: InputDecoration(
                                    hintText: 'Password',
                                    hintStyle: AppWidget.semiBoldTextFeildStyle(),
                                    prefixIcon: const Icon(Icons.lock_outline),
                                  ),
                                ),
                                const SizedBox(height: 40.0),

                                // 🔹 Sign Up Button
                                GestureDetector(
                                  onTap: () async {
                                    if (_formkey.currentState!.validate()) {
                                      setState(() {
                                        email = mailcontroller.text;
                                        name = namecontroller.text;
                                        password = passwordcontroller.text;
                                      });
                                      registration();
                                    }
                                  },
                                  child: Material(
                                    elevation: 5.0,
                                    borderRadius: BorderRadius.circular(20),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 10.0,
                                      ),
                                      width: 200, // Fixed width like Login
                                      decoration: BoxDecoration(
                                        color: const Color(0Xffff5722),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: const Center(
                                        child: Text(
                                          "SIGN UP",
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

                      const SizedBox(height: 40.0),

                      // 🔸 Login link (with RichText style)
                      GestureDetector(
                        onTap: () {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (context) => const LogIn()),
                          );
                        },
                        child: RichText(
                          text: TextSpan(
                            children: [
                              TextSpan(
                                text: "Already have an account? ",
                                style: AppWidget.semiBoldTextFeildStyle().copyWith(
                                  color: Colors.black,
                                ),
                              ),
                              TextSpan(
                                text: "Login",
                                style: AppWidget.semiBoldTextFeildStyle().copyWith(
                                  color: const Color(0Xffff5722), // Orange color
                                ),
                              ),
                            ],
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
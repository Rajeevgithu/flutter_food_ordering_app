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
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFff5c30), Color(0xFFe74b1a)],
            ),
          ),
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 🔸 Logo
                Image.asset(
                  "images/logo.png",
                  width: size.width * 0.6,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 30),

                // 🔹 Card with Form
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 25,
                  ),
                  child: Form(
                    key: _formkey,
                    child: Column(
                      children: [
                        Text(
                          "Sign Up",
                          style: AppWidget.HeadlineTextFeildStyle(),
                        ),
                        const SizedBox(height: 25),

                        // 🔸 Name
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
                        const SizedBox(height: 20),

                        // 🔸 Email
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
                        const SizedBox(height: 20),

                        // 🔸 Password
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
                        const SizedBox(height: 30),

                        // 🔸 Sign Up Button
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
                          child: Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0Xffff5722),
                              borderRadius: BorderRadius.circular(15),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.orangeAccent.withOpacity(0.4),
                                  blurRadius: 6,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "SIGN UP",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                // 🔹 Already have account
                GestureDetector(
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LogIn()),
                    );
                  },
                  child: Text(
                    "Already have an account? Login",
                    style: AppWidget.semiBoldTextFeildStyle(),
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

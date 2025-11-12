package com.example.e_commerce_app

import io.flutter.embedding.android.FlutterFragmentActivity // Change 1: Import the Fragment Activity

class MainActivity: FlutterFragmentActivity() { // Change 2: Use FlutterFragmentActivity
    // No code change required inside the class body.
    // Stripe requires this base class for proper initialization.
}
plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android") // ✅ Correct Kotlin DSL plugin
    // The Flutter Gradle Plugin must be applied after Android and Kotlin plugins
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
}

android {
    namespace = "com.example.e_commerce_app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.example.e_commerce_app"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = "17"
    }

    buildTypes {
        release {
            // TODO: Replace with your actual release keystore before publishing
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
        debug {
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    // ✅ Optional but recommended for better Gradle cache and reproducibility
    packaging {
        resources.excludes += setOf(
            "META-INF/LICENSE*",
            "META-INF/NOTICE*"
        )
    }
}

flutter {
    source = "../.."
}

dependencies {
    // ✅ Firebase BOM (Bill of Materials)
    implementation(platform("com.google.firebase:firebase-bom:34.5.0"))

    // ✅ Firebase Analytics
    implementation("com.google.firebase:firebase-analytics")

    // ✅ Material Components (fixes missing Theme.Material3.* styles)
    implementation("com.google.android.material:material:1.12.0")

    // ✅ Square In-App Payments SDK
    implementation("com.squareup.sdk.in-app-payments:card-entry:1.6.4")
}

// ✅ Ensure repositories are available for dependencies
repositories {
    google()
    mavenCentral()
    // ✅ Square public Maven repository for In-App Payments SDK
    maven { url = uri("https://sdk.squareup.com/public/android") }
}

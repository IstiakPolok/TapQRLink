import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("com.google.gms.google-services")  // Firebase services plugin
    id("kotlin-android")  // Kotlin plugin
    id("dev.flutter.flutter-gradle-plugin")  // Flutter plugin (must be applied last)
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.qr_code.qr_code"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = "27.0.12077973"  // Adjust if necessary

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
        isCoreLibraryDesugaringEnabled = true  // Enable desugaring for Java 8 APIs
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()  // Use JVM target 11
    }

    defaultConfig {
        applicationId = "com.tapqrlink.tapqrlink"  // Your unique package name
        minSdk = 24  // Minimum SDK version
        targetSdk = 35  // Target SDK version
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // Signing configuration for the release build
    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String
            keyPassword = keystoreProperties["keyPassword"] as String
            storeFile = keystoreProperties["storeFile"]?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")  // Use release signing config
            // You can also set minifyEnabled or other release optimizations here if needed
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")  // Enable Java 8+ features
}

flutter {
    source = "../.."  // Path to Flutter source
}

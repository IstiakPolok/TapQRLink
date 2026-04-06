pluginManagement {
    // Dynamically load the Flutter SDK path from local.properties
    val flutterSdkPath = run {
        val properties = java.util.Properties()
        file("local.properties").inputStream().use { properties.load(it) }
        val flutterSdkPath = properties.getProperty("flutter.sdk")
        require(flutterSdkPath != null) { "flutter.sdk not set in local.properties" }
        flutterSdkPath
    }

    // Include the Flutter tools for the build
    includeBuild("$flutterSdkPath/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

plugins {
    // Flutter plugin loader
    id("dev.flutter.flutter-plugin-loader") version "1.0.0"

    // Android application plugin (set apply false to apply in subproject)
    id("com.android.application") version "8.9.1" apply false

    // Firebase plugin (set apply false to apply in subproject)
    id("com.google.gms.google-services") version "4.3.15" apply false

    // Kotlin plugin for Android (set apply false to apply in subproject)
    id("org.jetbrains.kotlin.android") version "2.1.0" apply false
}

// Include the app module in the project
include(":app")

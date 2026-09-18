import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
} else {
    val altFile = file("../key.properties")
    if (altFile.exists()) {
        keystoreProperties.load(FileInputStream(altFile))
    }
}

android {
    namespace = "com.kolkatapuja.kolkata_puja"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.kolkatapuja.kolkata_puja"
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String? ?: "pujoparikrama"
            keyPassword = keystoreProperties["keyPassword"] as String? ?: "PujoParikrama2026!"
            val storeFilePath = keystoreProperties["storeFile"] as String? ?: "release-keystore.jks"
            storeFile = if (file(storeFilePath).exists()) {
                file(storeFilePath)
            } else if (file("../$storeFilePath").exists()) {
                file("../$storeFilePath")
            } else {
                file("release-keystore.jks")
            }
            storePassword = keystoreProperties["storePassword"] as String? ?: "PujoParikrama2026!"
            enableV1Signing = true
            enableV2Signing = true
            enableV3Signing = true
            enableV4Signing = true
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists() || file("release-keystore.jks").exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}

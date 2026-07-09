plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin applies the Kotlin Android plugin (built-in Kotlin).
    // KGP is declared on the classpath in settings.gradle.kts.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.arma.vpn"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.arma.vpn"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = 24
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true  // Required for Go native libs in AAR
        }
    }
}

flutter {
    source = "../.."
}

// Rename APK after build with proper task hooks
afterEvaluate {
    tasks.register("renameDebugApk") {
        doLast {
            val apkDir = File(buildDir, "outputs/flutter-apk")
            val oldName = "app-debug.apk"
            val oldFile = File(apkDir, oldName)
            
            if (oldFile.exists()) {
                val versionName = android.defaultConfig.versionName
                val newName = "ArmaVPN-debug-${versionName}.apk"
                val newFile = File(apkDir, newName)
                // Copy file to keep original for Flutter tool detection
                oldFile.copyTo(newFile, overwrite = true)
                println("✓ Created: $newName")
            }
        }
    }

    tasks.register("renameReleaseApk") {
        doLast {
            val apkDir = File(buildDir, "outputs/flutter-apk")
            val oldName = "app-release.apk"
            val oldFile = File(apkDir, oldName)
            
            if (oldFile.exists()) {
                val versionName = android.defaultConfig.versionName
                val newName = "ArmaVPN-release-${versionName}.apk"
                val newFile = File(apkDir, newName)
                // Copy file to keep original for Flutter tool detection
                oldFile.copyTo(newFile, overwrite = true)
                println("✓ Created: $newName")
            }
        }
    }

    // Hook rename tasks to assembleDebug and assembleRelease
    tasks.named("assembleDebug") {
        finalizedBy("renameDebugApk")
    }

    tasks.named("assembleRelease") {
        finalizedBy("renameReleaseApk")
    }
}

dependencies {
    implementation(fileTree(mapOf("dir" to "libs", "include" to listOf("*.aar"))))
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}

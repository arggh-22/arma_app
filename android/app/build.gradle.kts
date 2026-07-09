import java.io.FileInputStream
import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin applies the Kotlin Android plugin (built-in Kotlin).
    // KGP is declared on the classpath in settings.gradle.kts.
    id("dev.flutter.flutter-gradle-plugin")
}

// Release signing is driven by android/key.properties, which CI writes from
// GitHub Secrets (see .github/workflows/release.yml). When the file is absent
// (local dev, forks without secrets) we fall back to debug signing so
// `flutter run --release` and local APK builds keep working.
val keystorePropertiesFile = rootProject.file("key.properties")
val keystoreProperties = Properties().apply {
    if (keystorePropertiesFile.exists()) {
        load(FileInputStream(keystorePropertiesFile))
    }
}
val hasReleaseSigning = keystorePropertiesFile.exists()

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

    signingConfigs {
        if (hasReleaseSigning) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            // Real upload-key signing when key.properties is present (CI);
            // debug signing otherwise so local release builds still run.
            signingConfig = if (hasReleaseSigning) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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

plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    // ⚙️ Flutter plugin (luôn để cuối cùng)
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.vietflow.app"
    compileSdk = 35
    ndkVersion = "27.0.12077973"

    defaultConfig {
        applicationId = "com.vietflow.app"
        minSdk = 23
        targetSdk = 35
        versionCode = 1
        versionName = "1.0.0"
    }

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildTypes {
        // 🧱 Debug build (dành cho chạy thử)
        getByName("debug") {
            isMinifyEnabled = false
            isShrinkResources = false
            signingConfig = signingConfigs.getByName("debug")
        }

        // 🚀 Release build (dành cho build APK thật)
        getByName("release") {
            // ✅ Dùng debug key để test bản release cho tiện
            signingConfig = signingConfigs.getByName("debug")

            // 🚫 Tắt R8 để tránh lỗi java.awt.*
            // Nếu sau này bạn muốn bật lại, đổi true + thêm luật trong proguard-rules.pro
            isMinifyEnabled = false
            isShrinkResources = false

            // ⚙️ File cấu hình ProGuard (để dễ bật R8 khi cần)
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}

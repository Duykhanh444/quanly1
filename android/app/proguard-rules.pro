# --- Fix lỗi java.awt.* khi build release ---
-dontwarn java.awt.**
-keep class java.awt.** { *; }
-dontwarn java.awt.color.**
-dontwarn java.awt.image.**
-keep class java.awt.image.** { *; }
-dontwarn com.github.jaiimageio.**
-keep class com.github.jaiimageio.** { *; }

# --- Giữ lại class Flutter quan trọng ---
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class androidx.lifecycle.DefaultLifecycleObserver
-keepclassmembers class * implements androidx.lifecycle.DefaultLifecycleObserver {
    <methods>;
}

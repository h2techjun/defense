# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Flutter Play Store Split (optional deferred components — not used in this app)
-dontwarn com.google.android.play.core.**
-dontwarn io.flutter.embedding.android.FlutterPlayStoreSplitApplication
-dontwarn io.flutter.embedding.engine.deferredcomponents.**

# Supabase / Postgrest
-keep class io.supabase.** { *; }
-dontwarn io.supabase.**

# Kotlin
-keep class kotlin.** { *; }
-dontwarn kotlin.**

# Keep Dart entry points
-keep class com.gatewayofregrets.app.** { *; }

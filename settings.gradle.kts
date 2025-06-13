import java.util.Properties
import org.gradle.api.GradleException

pluginManagement {
    val properties = java.util.Properties()
    file("local.properties").inputStream().use { properties.load(it) }

    val flutterSdkLocation = properties.getProperty("flutter.sdk")
        ?: throw GradleException("flutter.sdk not set in local.properties")

    includeBuild("$flutterSdkLocation/packages/flutter_tools/gradle")

    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }

    plugins {
        id("com.android.application") version "8.3.0" apply false
        id("org.jetbrains.kotlin.android") version "1.8.20"
        id("dev.flutter.flutter-gradle-plugin") version "0.0.1" 
    }
}

rootProject.name = "flutter_application_1"
include(":android", ":app")

import org.gradle.api.GradleException
import java.util.Properties

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val releaseKeystoreProperties = Properties()
val releaseKeystorePropertiesFile = rootProject.file("key.properties")
val hasReleaseKeystore = releaseKeystorePropertiesFile.exists()

fun releaseKeystoreProperty(name: String): String =
    releaseKeystoreProperties.getProperty(name)?.takeIf { it.isNotBlank() }
        ?: throw GradleException(
            "android/key.properties must define `$name` for release signing.",
        )

if (hasReleaseKeystore) {
    releaseKeystorePropertiesFile.inputStream().use(releaseKeystoreProperties::load)
}

android {
    namespace = "app.unitana"
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
        applicationId = "app.unitana"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        if (hasReleaseKeystore) {
            create("release") {
                storeFile = rootProject.file(releaseKeystoreProperty("storeFile"))
                storePassword = releaseKeystoreProperty("storePassword")
                keyAlias = releaseKeystoreProperty("keyAlias")
                keyPassword = releaseKeystoreProperty("keyPassword")
            }
        }
    }

    buildTypes {
        release {
            if (hasReleaseKeystore) {
                signingConfig = signingConfigs.getByName("release")
            }
        }
    }
}

if (gradle.startParameter.taskNames.any { it.contains("Release", ignoreCase = true) } &&
    !hasReleaseKeystore
) {
    throw GradleException(
        "Release signing requires app/unitana/android/key.properties. " +
            "Release builds must not use debug signing.",
    )
}

flutter {
    source = "../.."
}

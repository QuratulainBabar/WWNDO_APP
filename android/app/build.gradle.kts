plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.wwngo.wwngo_app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildToolsVersion = "36.1.0"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.wwngo.wwngo_app"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro",
            )
        }
    }

    lint {
        checkReleaseBuilds = false
        abortOnError = false
    }

    packaging {
        jniLibs {
            useLegacyPackaging = true
            pickFirsts += setOf("**/libc++_shared.so")
        }
    }
}

flutter {
    source = "../.."
}

// Sumsub TensorFlow Lite needs libc++ at runtime. Missing this .so makes Vivo
// kill the app on launch (UnsatisfiedLinkError is not caught by plugin init).
tasks.register<Copy>("copyLibCppShared") {
    val ndkRoot = android.ndkDirectory
    from(
        ndkRoot.resolve(
            "toolchains/llvm/prebuilt/linux-x86_64/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so",
        ),
    )
    into(layout.projectDirectory.dir("src/main/jniLibs/arm64-v8a"))
}

tasks.named("preBuild").configure {
    dependsOn("copyLibCppShared")
}

dependencies {
    // Required by SumSub face detector (com.google.android.gms.tasks.Tasks)
    implementation("com.google.android.gms:play-services-tasks:18.2.1")
}

// Stripe issuing push-provisioning pulls a missing Play Services artifact;
// not needed for Payment Sheet / Connect.
configurations.configureEach {
    exclude(group = "com.stripe", module = "stripe-android-issuing-push-provisioning")
}

import java.util.Properties

plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystorePropertiesFile.inputStream().use { keystoreProperties.load(it) }
}

android {
    namespace = "com.wwngo.app"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion
    buildToolsVersion = "36.1.0"

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.wwngo.app"
        minSdk = maxOf(23, flutter.minSdkVersion)
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties.getProperty("keyAlias")
            keyPassword = keystoreProperties.getProperty("keyPassword")
            storeFile = file(keystoreProperties.getProperty("storeFile") ?: "keystore.jks")
            storePassword = keystoreProperties.getProperty("storePassword")
        }
    }

    buildTypes {
        release {
            signingConfig = if (keystorePropertiesFile.exists()) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
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
    val osName = System.getProperty("os.name").lowercase()
    val hostPrebuilt = when {
        osName.contains("windows") -> "windows-x86_64"
        osName.contains("mac") -> "darwin-x86_64"
        else -> "linux-x86_64"
    }
    val soFile = ndkRoot.resolve(
        "toolchains/llvm/prebuilt/$hostPrebuilt/sysroot/usr/lib/aarch64-linux-android/libc++_shared.so",
    )
    from(soFile)
    into(layout.projectDirectory.dir("src/main/jniLibs/arm64-v8a"))
    onlyIf { soFile.isFile }
}

tasks.named("preBuild").configure {
    dependsOn("copyLibCppShared")
}

dependencies {
    // Required by flutter_local_notifications on API < 26.
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
    // Required by SumSub face detector (com.google.android.gms.tasks.Tasks)
    implementation("com.google.android.gms:play-services-tasks:18.2.1")
    // Required by flutter_stripe Payment Sheet (Theme.MaterialComponents)
    implementation("com.google.android.material:material:1.12.0")
}

if (file("google-services.json").exists()) {
    apply(plugin = "com.google.gms.google-services")
}

// Stripe issuing push-provisioning pulls a missing Play Services artifact;
// not needed for Payment Sheet / Connect.
configurations.configureEach {
    exclude(group = "com.stripe", module = "stripe-android-issuing-push-provisioning")
    resolutionStrategy {
        // Avoid Android PaymentSheet card-number focus bug with lifecycle 2.9.x.
        force("androidx.lifecycle:lifecycle-runtime-ktx:2.8.7")
        force("androidx.lifecycle:lifecycle-viewmodel-ktx:2.8.7")
        force("androidx.lifecycle:lifecycle-common:2.8.7")
    }
}

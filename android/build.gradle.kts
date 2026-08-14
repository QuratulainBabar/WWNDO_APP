import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        maven { url = uri("${rootDir}/local-maven") }
        google()
        mavenCentral()
        // Sumsub only — do not resolve Stripe/Google artifacts from this host.
        maven {
            url = uri("https://maven.sumsub.com/repository/maven-releases/")
            content {
                includeGroupByRegex("com\\.sumsub.*")
            }
        }
        maven {
            url = uri("https://maven.sumsub.com/repository/maven-public/")
            content {
                includeGroupByRegex("com\\.sumsub.*")
            }
        }
    }
}

val newBuildDir: Directory =
    rootProject.layout.buildDirectory
        .dir("../../build")
        .get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    afterEvaluate {
        extensions.findByType(LibraryExtension::class.java)?.let { android ->
            if (name == "jni" || name == "jni_flutter") {
                android.compileSdk = 36
            }
            android.compileOptions {
                sourceCompatibility = JavaVersion.VERSION_17
                targetCompatibility = JavaVersion.VERSION_17
            }
        }

        tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
            compilerOptions {
                jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
            }
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

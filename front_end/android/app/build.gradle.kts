// Aplicació de plugins necessaris per compilar apps Android amb Flutter i Kotlin
plugins {
    id("com.android.application")
    id("kotlin-android")
    // El plugin de Flutter s'ha d'aplicar després dels d'Android i Kotlin
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.front_end"

    // Valors definits al bloc flutter {} (heretats del fitxer .metadata de Flutter)
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.front_end"  // Canvia-ho si ho vols pujar a Google Play
        minSdk = flutter.minSdkVersion           // Per Android 5.0 o superior
        targetSdk = flutter.targetSdkVersion     // Generalment 33 o superior
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // De moment fem servir les claus de debug per poder compilar en release amb `flutter run --release`
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    // Indica on és la root del projecte Flutter (dos nivells per sobre)
    source = "../.."
}

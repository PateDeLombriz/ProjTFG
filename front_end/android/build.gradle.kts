// Bloc necessari per indicar els plugins de construcció per a Android i Kotlin
buildscript {
    val kotlin_version by extra("1.8.10") // Versió compatible amb Gradle 8 i Flutter
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        classpath("com.android.tools.build:gradle:8.0.0")
        classpath("org.jetbrains.kotlin:kotlin-gradle-plugin:$kotlin_version")
    }
}

// Bloc original del projecte: defineix repositoris comuns
allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Canviem la ruta de les carpetes de build per a una millor organització
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}

// Ens assegurem que els subprojectes s'avaluïn després del mòdul :app
subprojects {
    project.evaluationDependsOn(":app")
}

// Task per netejar els fitxers de build
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

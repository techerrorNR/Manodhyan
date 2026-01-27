import com.android.build.gradle.LibraryExtension

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}



subprojects {
    plugins.withId("com.android.library") {
        val subProject = project
        
        if (subProject.name == "device_installed_apps") {
            subProject.extensions.findByType(LibraryExtension::class.java)?.let { androidExt ->
                if (androidExt.namespace.isNullOrBlank()) {
                    androidExt.namespace = "com.hofinity.device_installed_apps"
                }
            }
        }
        
        if (subProject.name == "usage_stats") {
  subProject.extensions.findByType(LibraryExtension::class.java)?.apply {
    println("Forcing compileSdk 35 for usage_stats")
    compileSdk = 35
    compileOptions {
      sourceCompatibility = JavaVersion.VERSION_17
      targetCompatibility = JavaVersion.VERSION_17
    }
  }
}

    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}


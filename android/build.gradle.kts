allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

// Define the custom build directory path
val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    // Set custom build directory for each subproject
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)

    // Ensure :app is evaluated before other subprojects
    project.evaluationDependsOn(":app")
}

// Define the clean task to delete the custom build directory
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

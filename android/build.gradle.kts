allprojects {
    repositories {
        google()
        mavenCentral()
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
// Some plugins (e.g. agora_rtc_engine) still compile against an old Android SDK.
// Compile every Android library plugin against SDK 36 so the build works.
subprojects {
    val forceCompileSdk: () -> Unit = {
        extensions.findByName("android")?.let { ext ->
            if (ext is com.android.build.gradle.LibraryExtension) {
                ext.compileSdk = 36
            }
        }
    }
    if (state.executed) forceCompileSdk() else afterEvaluate { forceCompileSdk() }
}
subprojects {
    project.evaluationDependsOn(":app")
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

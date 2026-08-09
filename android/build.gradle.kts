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

subprojects {
    project.evaluationDependsOn(":app")
}

fun Project.forceLibraryCompileSdk36() {
    if (!plugins.hasPlugin("com.android.library")) return

    val androidExt = extensions.findByName("android") ?: return
    val setter =
        androidExt.javaClass.methods.firstOrNull {
            it.name == "setCompileSdk" && it.parameterCount == 1
        }
            ?: androidExt.javaClass.methods.firstOrNull {
                it.name == "setCompileSdkVersion" && it.parameterCount == 1
            }

    setter?.let {
        it.isAccessible = true
        it.invoke(androidExt, 36)
    }
}

subprojects {
    // Safe when evaluationDependsOn(":app") has already evaluated the project.
    if (state.executed) {
        forceLibraryCompileSdk36()
    } else {
        afterEvaluate { forceLibraryCompileSdk36() }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

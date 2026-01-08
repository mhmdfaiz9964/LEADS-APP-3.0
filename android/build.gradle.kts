extra["kotlin_version"] = "2.1.0"

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
    afterEvaluate {
        val project = this
        if (project.hasProperty("android")) {
            val android = project.extensions.findByName("android")
            if (android != null) {
                // Force compileSdk 35 for all modules to fix lStar error
                try {
                    val setCompileSdk = android.javaClass.methods.find { it.name == "setCompileSdk" }
                    setCompileSdk?.invoke(android, 35)
                } catch (e: Exception) {}

                // Check if namespace is already set
                val getNamespace = android.javaClass.methods.find { it.name == "getNamespace" }
                val setNamespace = android.javaClass.methods.find { it.name == "setNamespace" }
                val currentNamespace = getNamespace?.invoke(android) as? String

                if (currentNamespace.isNullOrBlank()) {
                    val manifestFile = project.file("src/main/AndroidManifest.xml")
                    if (manifestFile.exists()) {
                        val manifestContent = manifestFile.readText()
                        val packageMatch = Regex("package=\"([^\"]*)\"").find(manifestContent)
                        if (packageMatch != null) {
                            val packageName = packageMatch.groupValues[1]
                            setNamespace?.invoke(android, packageName)
                        }
                    }
                }
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

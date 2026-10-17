allprojects {
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://developer.magiclane.com/packages/android")
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
    val configureAndroid = {
        val android = project.extensions.findByName("android")
        if (android != null) {
            try {
                val method = android.javaClass.getMethod("compileSdkVersion", Int::class.javaPrimitiveType)
                method.invoke(android, 36)
            } catch (_: Throwable) {
                try {
                    val method = android.javaClass.getMethod("setCompileSdkVersion", Int::class.javaPrimitiveType)
                    method.invoke(android, 36)
                } catch (_: Throwable) {}
            }
        }
    }

    if (state.executed) {
        configureAndroid()
    } else {
        afterEvaluate {
            configureAndroid()
        }
    }

}

subprojects {
    project.evaluationDependsOn(":app")

    // MapLibre 0.27 emits Java 21 classes. Select its compiler before Android
    // creates the compile tasks; other plugins retain their own toolchains.
    if (name == "maplibre_gl") {
        pluginManager.withPlugin("com.android.library") {
            val toolchains = extensions.getByType<org.gradle.jvm.toolchain.JavaToolchainService>()
            tasks.withType<JavaCompile>().configureEach {
                javaCompiler.set(toolchains.compilerFor {
                    languageVersion.set(JavaLanguageVersion.of(21))
                })
            }
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

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
    afterEvaluate {
        extensions.findByType<com.android.build.gradle.BaseExtension>()?.apply {
            compileSdkVersion(36)
        }
    }
}
subprojects {
    project.evaluationDependsOn(":app")
}
subprojects {
    tasks.withType<org.jetbrains.kotlin.gradle.tasks.KotlinCompile>().configureEach {
        val target = project.extensions.findByType<com.android.build.gradle.BaseExtension>()
            ?.compileOptions?.targetCompatibility?.toString() ?: "1.8"
        val jvmTargetVal = when (target) {
            "1.8" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
            "17" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
            "21" -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_21
            else -> org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_1_8
        }
        compilerOptions {
            jvmTarget.set(jvmTargetVal)
        }
    }
}



tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}

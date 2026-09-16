import java.security.MessageDigest
import java.text.SimpleDateFormat
import java.util.Date
import java.math.BigInteger
import com.android.build.gradle.LibraryExtension
import org.gradle.api.DefaultTask
import org.gradle.api.provider.ListProperty
import org.gradle.api.provider.Property
import org.gradle.api.tasks.Input
import org.gradle.api.tasks.Optional
import org.gradle.api.tasks.TaskAction
import java.util.Properties
import java.util.zip.ZipFile
import org.jetbrains.kotlin.gradle.dsl.JvmTarget

group = "com.magiclane.magiclane_maps_flutter"
version = "3.1.11"

plugins {
    id("com.android.library")
}

val agpMajorVersion = com.android.Version.ANDROID_GRADLE_PLUGIN_VERSION.substringBefore('.').toInt()
if (agpMajorVersion < 9) {
    apply(plugin = "org.jetbrains.kotlin.android")
}

android {
    compileSdk = 36
    defaultConfig {
        minSdk = 21
    }

    namespace = "com.magiclane.magiclane_maps_flutter"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    sourceSets {
        getByName("main") {
            java.srcDirs("src/main/kotlin")
        }
    }

    buildTypes {
        getByName("debug") {
            buildConfigField("boolean", "USE_INTERNAL_PATH", "false")
            buildConfigField("boolean", "USE_EARLY_INIT", "false")
        }
        getByName("release") {
            buildConfigField("boolean", "USE_INTERNAL_PATH", "false")
            buildConfigField("boolean", "USE_EARLY_INIT", "false")
        }
        create("profile") {
            buildConfigField("boolean", "USE_INTERNAL_PATH", "false")
            buildConfigField("boolean", "USE_EARLY_INIT", "false")
        }
    }

    buildFeatures {
        buildConfig = true
    }
}

extensions.configure<org.jetbrains.kotlin.gradle.dsl.KotlinAndroidProjectExtension> {
    compilerOptions {
        jvmTarget = JvmTarget.JVM_11
    }
}

abstract class ExtractNdkVersionTask : DefaultTask() {

    @get:Input
    @get:Optional
    abstract val localAarFiles: ListProperty<File>

    @get:Input
    abstract val usesLocalAar: Property<Boolean>

    @get:Input
    @get:Optional
    abstract val localMavenRepoPath: Property<String>

    init {
        group = "magiclane_maps_flutter"
        description = "Extracts NDK version from AAR (local or Maven) and applies it to the Android project"
    }

    @TaskAction
    fun extractAndApplyNdkVersion() {
        var aarFile: File? = null

        // First, try to use local AAR if available
        if (usesLocalAar.getOrElse(false) && localAarFiles.isPresent) {
            val files = localAarFiles.get()
            if (files.isNotEmpty()) {
                aarFile = files.firstOrNull {
                    it.name.contains("com.magiclane") || it.name.contains("maps-flutter-kotlin")
                } ?: files.first()

                aarFile?.let { logger.warn("Using local AAR: ${it.name}") }
            }
        }

        // If still no AAR found, try local Maven repo
        if (aarFile == null && localMavenRepoPath.isPresent) {
            aarFile = findAarInLocalMavenRepo(localMavenRepoPath.get())
            aarFile?.let { logger.warn("Using AAR from local Maven repo: ${it.name}") }
        }

        // Finally, try Gradle cache
        if (aarFile == null) {
            aarFile = findAarInGradleCache(project)
            aarFile?.let { logger.warn("Using AAR from Gradle cache: ${it.name}") }
        }

        if (aarFile == null) {
            logger.warn("No AAR file found - NDK version will not be set automatically")
            return
        }

        val ndkVersion = extractNdkVersionFromAar(aarFile)

        if (ndkVersion != null) {
            applyNdkVersion(project, ndkVersion, aarFile.name)
        } else {
            logger.warn("Could not extract NDK version from ${aarFile.name}")
        }
    }

    private fun findAarInLocalMavenRepo(localMavenPath: String): File? {
        val localMavenDir = File(localMavenPath)

        if (!localMavenDir.exists()) {
            return null
        }

        return localMavenDir.walkTopDown()
            .filter { it.extension == "aar" }
            .firstOrNull()
    }

    private fun findAarInGradleCache(project: org.gradle.api.Project): File? {
        val gradleUserHome = project.gradle.gradleUserHomeDir
        val possibleCachePaths = listOf(
            File(gradleUserHome, "caches/modules-2/files-2.1/com.magiclane/maps-flutter-kotlin"),
            File(gradleUserHome, "caches/transforms-3"),
            File(gradleUserHome, "caches/transforms-4")
        )

        for (cacheDir in possibleCachePaths) {
            if (cacheDir.exists()) {
                val aarFile = cacheDir.walkTopDown()
                    .filter { it.extension == "aar" }
                    .filter { it.name.contains("maps-flutter-kotlin") || it.name.contains("com.magiclane") }
                    .firstOrNull()

                if (aarFile != null) {
                    return aarFile
                }
            }
        }

        return null
    }

    private fun extractNdkVersionFromAar(aarFile: File): String? = try {
        ZipFile(aarFile).use { zip ->
            val metadataEntry = zip.getEntry("META-INF/com/android/build/gradle/aar-metadata.properties")

            if (metadataEntry != null) {
                val props = Properties()
                zip.getInputStream(metadataEntry).use { props.load(it) }
                props.getProperty("compileNdkVersion")
            } else {
                logger.warn("AAR metadata not found in ${aarFile.name}")
                null
            }
        }
    } catch (e: Exception) {
        logger.error("Failed to extract NDK version from ${aarFile.name}: ${e.message}")
        null
    }

    private fun applyNdkVersion(project: org.gradle.api.Project, ndkVersion: String, aarFileName: String) {
        var applied = false

        project.extensions.findByType(LibraryExtension::class.java)?.apply {
            this.ndkVersion = ndkVersion
            logger.warn("Applied NDK version '$ndkVersion' to LibraryExtension from '$aarFileName'")
            applied = true
        }

        if (!applied) {
            logger.warn("Could not apply NDK version - no Android extension found")
        }
    }
}

val localMavenPath = project.file("build/local-maven").absolutePath
var useLocalAar = false
val localAarFiles = mutableListOf<File>()

// Check for local AAR files and publish them to local Maven repository
project.file("libs").let { libsDir ->
    if (libsDir.exists() && libsDir.isDirectory) {
        val aarFiles = libsDir.listFiles { file -> file.extension == "aar" }

        if (!aarFiles.isNullOrEmpty()) {
            useLocalAar = true
            localAarFiles.addAll(aarFiles)

            logger.warn(
                """
                ------------------------------------------------------------------
                Found local AAR file(s) - publishing to local Maven repository
                ------------------------------------------------------------------
                """.trimIndent()
            )

            aarFiles.forEach { aarFile ->
                logger.warn("  - ${aarFile.name}")

                // Parse AAR filename: groupId-artifactId-version.aar
                val aarName = aarFile.nameWithoutExtension
                val parts = aarName.split("-")

                if (parts.size >= 3) {
                    val groupId = parts[0]
                    val artifactId = parts.subList(1, parts.size - 1).joinToString("-")
                    val version = parts.last()

                    val targetPath = "$localMavenPath/${groupId.replace(".", "/")}/$artifactId/$version"
                    val targetDir = file(targetPath)
                    val targetAar = File(targetDir, "$artifactId-$version.aar")

                    if (!targetAar.exists() || targetAar.lastModified() < aarFile.lastModified()) {
                        logger.warn("Publishing: $groupId:$artifactId:$version")

                        targetDir.mkdirs()
                        aarFile.copyTo(targetAar, overwrite = true)

                        require(targetAar.length() == aarFile.length()) {
                            "Failed to copy AAR correctly. Source: ${aarFile.length()}, Target: ${targetAar.length()}"
                        }

                        val (sha1, md5) = getFileHashes(targetAar)
                        file("$targetPath/$artifactId-$version.aar.sha1").writeText(sha1)
                        file("$targetPath/$artifactId-$version.aar.md5").writeText(md5)

                        val pomFile = file("$targetPath/$artifactId-$version.pom")
                        pomFile.writeText(createPom(groupId, artifactId, version))
                        val (pomSha1, pomMd5) = getFileHashes(pomFile)
                        file("$targetPath/$artifactId-$version.pom.sha1").writeText(pomSha1)
                        file("$targetPath/$artifactId-$version.pom.md5").writeText(pomMd5)

                        val metadataFile = file("${targetDir.parent}/maven-metadata.xml")
                        metadataFile.writeText(createMavenMetadata(groupId, artifactId, version))
                        val (metaSha1, metaMd5) = getFileHashes(metadataFile)
                        file("${targetDir.parent}/maven-metadata.xml.sha1").writeText(metaSha1)
                        file("${targetDir.parent}/maven-metadata.xml.md5").writeText(metaMd5)
                    }
                }
            }
        }
    }
}

repositories {
    if (useLocalAar) {
        maven { url = uri(localMavenPath) }
    }
    maven {
        url = uri("https://developer.magiclane.com/packages/android")
    }
    google()
    mavenCentral()
}

dependencies {
    // Add AndroidX Media dependency for audio focus support
    implementation("androidx.media:media:1.7.0")

    if (useLocalAar) {
        // Use local Maven repository
        localAarFiles.forEach { aarFile ->
            val aarName = aarFile.nameWithoutExtension
            val parts = aarName.split("-")

            if (parts.size >= 3) {
                val groupId = parts[0]
                val artifactId = parts.subList(1, parts.size - 1).joinToString("-")
                val version = parts.last()

                implementation("$groupId:$artifactId:$version")
            }
        }

        // Exclude remote artifact to avoid conflicts
        configurations.configureEach {
            exclude(group = "com.magiclane", module = "maps-flutter-kotlin")
        }
    } else {
        // Use remote Maven artifact
        logger.warn(
            """
            ------------------------------------------------------------------
            Using remote Maven dependency: com.magiclane:maps-flutter-kotlin:$version
            ------------------------------------------------------------------
            """.trimIndent()
        )

        implementation("com.magiclane:maps-flutter-kotlin:$version")
    }
}

val topLocalAarFiles = localAarFiles
val topUsesLocalAar = useLocalAar
val topLocalMavenPath = localMavenPath

// Register and run NDK version extraction task
val extractNdkVersion = tasks.register<ExtractNdkVersionTask>("extractNdkVersion") {
    localAarFiles.set(topLocalAarFiles)
    usesLocalAar.set(topUsesLocalAar)
    localMavenRepoPath.set(topLocalMavenPath)
}

// Execute after project evaluation
project.afterEvaluate {
    extractNdkVersion.get().extractAndApplyNdkVersion()
}

fun createPom(groupId: String, artifactId: String, version: String) = """
    <?xml version="1.0" encoding="UTF-8"?>
    <project xmlns="http://maven.apache.org/POM/4.0.0"
             xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
             xsi:schemaLocation="http://maven.apache.org/POM/4.0.0
                                 http://maven.apache.org/xsd/maven-4.0.0.xsd">
        <modelVersion>4.0.0</modelVersion>
        <groupId>$groupId</groupId>
        <artifactId>$artifactId</artifactId>
        <version>$version</version>
        <packaging>aar</packaging>
    </project>
""".trimIndent()

fun createMavenMetadata(groupId: String, artifactId: String, version: String) = """
    <?xml version="1.0" encoding="UTF-8"?>
    <metadata>
        <groupId>$groupId</groupId>
        <artifactId>$artifactId</artifactId>
        <versioning>
            <release>$version</release>
            <versions>
                <version>$version</version>
            </versions>
            <lastUpdated>${SimpleDateFormat("yyyyMMdd").format(Date())}000000</lastUpdated>
        </versioning>
    </metadata>
""".trimIndent()

fun getFileHashes(file: File): Pair<String, String> = try {
    file.inputStream().use { input ->
        val sha1 = MessageDigest.getInstance("SHA-1")
        val md5 = MessageDigest.getInstance("MD5")
        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)

        generateSequence { input.read(buffer) }
            .takeWhile { it != -1 }
            .forEach { bytesRead ->
                sha1.update(buffer, 0, bytesRead)
                md5.update(buffer, 0, bytesRead)
            }

        sha1.digest().toHexString() to md5.digest().toHexString()
    }
} catch (e: Exception) {
    logger.error("Error calculating hashes: ${e.message}")
    "" to ""
}

fun ByteArray.toHexString(): String =
    BigInteger(1, this).toString(16).padStart(this.size * 2, '0')

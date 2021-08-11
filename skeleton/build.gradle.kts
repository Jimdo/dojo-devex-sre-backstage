import org.jetbrains.kotlin.gradle.tasks.KotlinCompile
import java.net.URI

buildscript {
    dependencies {
        classpath("com.google.cloud.tools:jib-spring-boot-extension-gradle:0.1.0")
    }
}

plugins {
    id("org.springframework.boot") version "2.5.3"
    id("io.spring.dependency-management") version "1.0.11.RELEASE"
    id("com.google.cloud.tools.jib") version "3.1.2"
    id("co.uzzu.dotenv.gradle") version "1.1.0"
    id("com.github.johnrengelman.processes") version "0.5.0"
    id("org.springdoc.openapi-gradle-plugin") version "1.3.2"
    id("org.jlleitschuh.gradle.ktlint")version "10.1.0"
    kotlin("jvm") version "1.5.21"
    kotlin("plugin.spring") version "1.5.21"
    kotlin("plugin.jpa") version "1.5.21"
}

group = "com.jimdo"
version = "0.0.1-SNAPSHOT"
java.sourceCompatibility = JavaVersion.VERSION_11

configurations {
    compileOnly {
        extendsFrom(configurations.annotationProcessor.get())
    }
}

repositories {
    mavenCentral()
    exclusiveContent {
        forRepository {
            maven {
                url = URI("https://maven.pkg.github.com/jimdo/packages")
                credentials {
                    username = "jimdo-bot"
                    password = "0aa814583c4d697ff06eba6a57b20ca9b8f25058" // Github token with Read:packages only
                }
            }
        }
        filter {
            // this repository *only* contains artifacts with group "com.jimdo" and at the same time is the *only*
            // possible source for "com.jimdo" artifacts
            includeGroup("com.jimdo")
        }
    }
}

val openTelemetry: Configuration by configurations.creating

val testcontainersVersion = "1.15.3"
val openTelemetryVersion = "1.2.0"
val springDocVersion = "1.5.10"
val logbackVersion = "1.2.5"
val logbackJsonVersion = "0.1.5"
val mockkVersion = "1.12.0"

dependencies {
    annotationProcessor("org.springframework.boot:spring-boot-configuration-processor")
    implementation("ch.qos.logback.contrib:logback-jackson:$logbackJsonVersion")
    implementation("ch.qos.logback.contrib:logback-json-classic:$logbackJsonVersion")
    implementation("ch.qos.logback:logback-classic:$logbackVersion")
    implementation("ch.qos.logback:logback-core:$logbackVersion")
    implementation("com.fasterxml.jackson.module:jackson-module-kotlin")
    implementation("com.jimdo:spring-security-simple-tokens-webmvc:1.1.0")
    implementation("org.flywaydb:flyway-core")
    implementation("org.jetbrains.kotlin:kotlin-reflect")
    implementation("org.jetbrains.kotlin:kotlin-stdlib-jdk8")
    implementation("org.springdoc:springdoc-openapi-kotlin:$springDocVersion")
    implementation("org.springdoc:springdoc-openapi-security:$springDocVersion")
    implementation("org.springdoc:springdoc-openapi-ui:$springDocVersion")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-cache")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-quartz")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-validation")
    implementation("org.springframework.boot:spring-boot-starter-web")
    openTelemetry("io.opentelemetry.javaagent:opentelemetry-javaagent:$openTelemetryVersion")
    runtimeOnly("io.micrometer:micrometer-registry-prometheus")
    runtimeOnly("org.postgresql:postgresql")
    testImplementation("org.springframework.boot:spring-boot-starter-test") {
        exclude(group = "org.junit.vintage", module = "junit-vintage-engine")
    }
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("io.mockk:mockk:$mockkVersion")
    testImplementation("org.testcontainers:junit-jupiter")
    testImplementation("org.testcontainers:postgresql")
}

dependencyManagement {
    imports {
        mavenBom("org.testcontainers:testcontainers-bom:$testcontainersVersion")
    }
}

val jibExtraFolder = "$buildDir/jibextra"

val copyOpenTelemetryAgent = tasks.register<Copy>("copyOpenTelemetryAgent") {
    from(openTelemetry.asPath)
    into(jibExtraFolder)
}

tasks.named("jibDockerBuild") {
    dependsOn(copyOpenTelemetryAgent)
}

jib {
    extraDirectories.setPaths(jibExtraFolder)
    container {
        jvmFlags = listOf("-javaagent:/${openTelemetry.singleFile.name}")
    }
}

openApi {
    apiDocsUrl.set("http://localhost:8080/docs/api-docs")
    outputDir.set(file("."))
    outputFileName.set("specification.json")
}

tasks.withType<KotlinCompile> {
    kotlinOptions {
        freeCompilerArgs = listOf("-Xjsr305=strict")
        jvmTarget = "11"
    }
}

tasks.withType<Test> {
    useJUnitPlatform()
    testLogging {
        events("PASSED", "FAILED", "SKIPPED")
        showStandardStreams = true
    }
}

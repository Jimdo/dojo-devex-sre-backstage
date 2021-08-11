package com.jimdo.template

import org.testcontainers.containers.PostgreSQLContainer

class TestingPostgreSQLContainer private constructor() :
    PostgreSQLContainer<TestingPostgreSQLContainer>(IMAGE_VERSION) {
    override fun start() {
        super.start()
        System.setProperty("DATABASE_ENDPOINT", instance.host)
        System.setProperty("DATABASE_NAME", instance.databaseName)
        System.setProperty("DATABASE_PASSWORD", instance.password)
        System.setProperty("DATABASE_PORT", instance.firstMappedPort.toString())
        System.setProperty("DATABASE_USER", instance.username)
    }

    override fun stop() {
        // do nothing, JVM handles shut down
    }

    companion object {
        private const val IMAGE_VERSION = "postgres:13"
        private val container: TestingPostgreSQLContainer = TestingPostgreSQLContainer()
        val instance: TestingPostgreSQLContainer
            get() {
                if (!container.isRunning) {
                    container.start()
                }
                return container
            }
    }
}

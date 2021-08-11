package com.jimdo.template

import org.junit.ClassRule
import org.junit.jupiter.api.Test
import org.springframework.boot.test.context.SpringBootTest
import org.testcontainers.containers.PostgreSQLContainer

@SpringBootTest
class ApplicationTests {
    @ClassRule
    var postgreSQLContainer: PostgreSQLContainer<*> = TestingPostgreSQLContainer.instance

    @Test
    fun contextLoads() {
    }
}

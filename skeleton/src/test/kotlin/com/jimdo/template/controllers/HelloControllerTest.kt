package com.jimdo.template.controllers

import com.jimdo.template.TestingPostgreSQLContainer
import com.jimdo.template.config.SecurityConfig.Companion.ROLE_API_USER
import com.jimdo.template.config.SecurityConfig.Companion.ROLE_DOCS_USER
import org.hamcrest.Matchers.containsString
import org.junit.ClassRule
import org.junit.jupiter.api.Test
import org.springframework.beans.factory.annotation.Autowired
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc
import org.springframework.boot.test.context.SpringBootTest
import org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user
import org.springframework.test.web.servlet.MockMvc
import org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.content
import org.springframework.test.web.servlet.result.MockMvcResultMatchers.status
import org.testcontainers.containers.PostgreSQLContainer

@SpringBootTest
@AutoConfigureMockMvc
private class HelloControllerTest {
    val apiUser = "apiUser"

    @ClassRule
    var postgreSQLContainer: PostgreSQLContainer<*> = TestingPostgreSQLContainer.instance

    @Autowired
    private lateinit var mockMvc: MockMvc

    @Test
    fun `should work with correct authentication`() {
        mockMvc
            .perform(get("/api/hello/world").with(user(apiUser).roles(ROLE_API_USER)))
            .andExpect(status().isOk)
            .andExpect(content().string(containsString("Hello world!")))
    }

    @Test
    fun `should be forbidden with incorrect role`() {
        mockMvc
            .perform(get("/api/hello/world").with(user(apiUser).roles(ROLE_DOCS_USER)))
            .andExpect(status().isForbidden)
    }

    @Test
    fun `should be unauthorized with no authentication`() {
        mockMvc
            .perform(get("/api/hello/world"))
            .andExpect(status().isUnauthorized)
    }
}

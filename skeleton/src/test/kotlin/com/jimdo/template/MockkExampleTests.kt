package com.jimdo.template

import com.jimdo.template.controllers.HelloController
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import org.junit.jupiter.api.Assertions.assertEquals
import org.junit.jupiter.api.Test

internal class MockkExampleTests {
    private val helloController: HelloController = mockk<HelloController>()
    @Test
    fun `test showing how to use mockk`() {
        // mock return values of the instance
        every { helloController.world() } returns "mocked"

        // assert that the mock worked, this should be a call to something that relies on the mocked instance
        assertEquals("mocked", helloController.world())

        // optional verification that a call with certain arguments (in this case none) were made
        verify { helloController.world() }
    }
}

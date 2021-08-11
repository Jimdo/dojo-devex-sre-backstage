package com.jimdo.template.controllers

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestMapping
import org.springframework.web.bind.annotation.RestController

@RestController()
@RequestMapping("/api/hello")
class HelloController {
    @GetMapping("/world")
    fun world(): String {
        return "Hello world!"
    }
}

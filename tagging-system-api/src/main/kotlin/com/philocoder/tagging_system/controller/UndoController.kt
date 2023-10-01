package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.service.UndoService
import org.springframework.web.bind.annotation.CrossOrigin
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController


@RestController
class UndoController(
    private val service: UndoService
) {

    @CrossOrigin
    @GetMapping("/undo")
    fun getInitialData(): String {
        service.undo()
        return "ok"
    }
}
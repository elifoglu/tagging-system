package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.service.DataService
import org.springframework.web.bind.annotation.CrossOrigin
import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RestController


@RestController
class UndoController(
    private val dataHolder: DataHolder,
    private val dataService: DataService
) {

    @ExperimentalStdlibApi
    @CrossOrigin
    @GetMapping("/undo")
    fun undo(): String {
        dataHolder.undo()

        dataService.writeAllDataToDataFile()
        return "ok"
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @GetMapping("/clear-undo-stack")
    fun clearUndoStack(): String {
        dataHolder.clearUndoStack()

        dataService.writeAllDataToDataFile()
        return "ok"
    }
}
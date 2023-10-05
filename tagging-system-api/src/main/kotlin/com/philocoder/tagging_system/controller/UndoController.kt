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
    fun getInitialData(): String {
        dataHolder.undo()

        dataService.writeAllDataToDataFile()
        return "ok"
    }
}
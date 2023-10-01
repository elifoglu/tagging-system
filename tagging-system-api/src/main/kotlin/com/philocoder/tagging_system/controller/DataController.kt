package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.request.AddAllDataRequest
import com.philocoder.tagging_system.model.request.GenerateDataRequest
import com.philocoder.tagging_system.model.request.GetAllDataResponse
import com.philocoder.tagging_system.service.DataService
import org.springframework.web.bind.annotation.CrossOrigin
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController


@RestController
class DataController(
    private val service: DataService
) {

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/add-all-data")
    fun addAllData(@RequestBody req: AddAllDataRequest): String {
        return service.addAllData(req)
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/get-all-data")
    fun getAllData(): GetAllDataResponse? {
        return service.getAllData()
    }
}
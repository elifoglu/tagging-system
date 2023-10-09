package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.request.AddAllDataRequest
import com.philocoder.tagging_system.model.request.GetAllDataResponse
import com.philocoder.tagging_system.service.DataService
import org.springframework.web.bind.annotation.*


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

    @ExperimentalStdlibApi
    @CrossOrigin
    @GetMapping("/remove-all-deleted-data")
    fun removeAllDeletedDataFromDataFile(): String {
        val allData = service.getAllData()!!
        val req =
            AddAllDataRequest(
                contents = allData.contents.filter { !it.isDeleted },
                tags = allData.tags.filter { !it.isDeleted },
                contentViewOrder = allData.contentViewOrder,
                homeTagId = allData.homeTagId
            )
        addAllData(req)
        service.writeAllDataToDataFile()
        return "ok"
    }
}
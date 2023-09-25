package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.AllData
import com.philocoder.tagging_system.model.request.AddAllDataRequest
import com.philocoder.tagging_system.model.request.GetAllDataResponse
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.service.ContentService
import org.springframework.web.bind.annotation.CrossOrigin
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController


@RestController
class DataController(
    private val dataHolder: DataHolder,
    private val contentService: ContentService
) {

    @CrossOrigin
    @PostMapping("/add-all-data")
    fun addAllData(@RequestBody req: AddAllDataRequest): String {
        val allData = AllData(
            contents = req.contents,
            tags = req.tags,
            homeTagId = req.homeTagId,
            wholeGraphData = contentService.createWholeGraphData(req.contents),
            graphDataOfContents = req.contents.map {
                it.contentId to contentService.createGraphDataForContent(
                    it,
                    req.contents
                )
            }
                .toMap()
        )
        dataHolder.addAllData(allData)
        return "ok"
    }

    @CrossOrigin
    @PostMapping("/get-all-data")
    fun getAllData(): GetAllDataResponse? {
        val allData: AllData = dataHolder.getAllData() ?: return null
        return GetAllDataResponse(
            allData.contents.sortedBy { it.contentId },
            allData.tags,
            allData.homeTagId
        )
    }

    @CrossOrigin
    @PostMapping("/clear-all-data")
    fun clearAllData(): String {
        dataHolder.clearData()
        return "ok"
    }
}
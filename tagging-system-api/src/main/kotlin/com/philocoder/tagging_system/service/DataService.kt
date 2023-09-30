package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.AllData
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.AddAllDataRequest
import com.philocoder.tagging_system.model.request.GetAllDataResponse
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Service
import org.springframework.web.bind.annotation.CrossOrigin
import org.springframework.web.bind.annotation.PostMapping
import org.springframework.web.bind.annotation.RequestBody
import org.springframework.web.bind.annotation.RestController
import java.util.*

@Service
class DataService(
    private val dataHolder: DataHolder
) {

    @ExperimentalStdlibApi
    fun addAllData(@RequestBody req: AddAllDataRequest): String {
        val parentToChildTagMap = HashMap<String, ArrayList<String>>()
        req.tags.forEach { tag ->
            val emptyList = ArrayList<String>()
            parentToChildTagMap[tag.tagId] = emptyList
        }
        req.tags.forEach { tag ->
            tag.parentTags.forEach { parentTagId ->
                val childTagIds: ArrayList<String> = parentToChildTagMap[parentTagId]!!
                childTagIds.add(tag.tagId)
                parentToChildTagMap[parentTagId] = childTagIds
            }
        }
        val allTags = req.tags.map { Tag.createWith(it, parentToChildTagMap) }
        val allContents = req.contents

        val allData = AllData(
            contents = allContents,
            tags = allTags,
            homeTagId = req.homeTagId
        )
        dataHolder.addAllData(allData)
        return "ok"
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/get-all-data")
    fun getAllData(): GetAllDataResponse? {
        val allData: AllData = dataHolder.getAllData() ?: return null
        return GetAllDataResponse(
            allData.contents.sortedBy { it.contentId },
            allData.tags.map { Tag.toWithoutChild(it) },
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
package com.philocoder.tagging_system.service

import com.google.gson.GsonBuilder
import com.philocoder.tagging_system.model.AllData
import com.philocoder.tagging_system.model.UserConfig
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.AddAllDataRequest
import com.philocoder.tagging_system.model.request.GenerateDataRequest
import com.philocoder.tagging_system.model.request.GetAllDataResponse
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Service
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.Paths
import java.util.*

@Service
class DataService(
    private val dataHolder: DataHolder,
    private val userConfig: UserConfig
) {

    @ExperimentalStdlibApi
    fun addAllData(req: AddAllDataRequest): String {
        val result = setWholeData(GenerateDataRequest(req.contents, req.tags, req.contentViewOrder, req.homeTagId))
        dataHolder.clearUndoStack()
        return result
    }

    @ExperimentalStdlibApi
    fun regenerateWholeData() { //this have to be called after every CRUD operation to do parentTags/childTags calculations from scratch
        val currentData = dataHolder.getAllData()
        val req = GenerateDataRequest(
            contents = currentData.contents,
            tags = currentData.tags.map { Tag.toWithoutChild(it) },
            contentViewOrder = currentData.contentViewOrder,
            homeTagId = currentData.homeTagId
        )
        setWholeData(req)
    }

    @ExperimentalStdlibApi
    private fun setWholeData(req: GenerateDataRequest): String {
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
            contentViewOrder = req.contentViewOrder,
            homeTagId = req.homeTagId
        )
        dataHolder.addAllData(allData)
        return "ok"
    }

    @ExperimentalStdlibApi
    fun getAllData(): GetAllDataResponse? {
        val allData: AllData = dataHolder.getAllData() ?: return null
        return GetAllDataResponse(
            allData.contents.sortedBy { it.contentId },
            allData.tags.map { Tag.toWithoutChild(it) },
            allData.contentViewOrder,
            allData.homeTagId
        )
    }

    @ExperimentalStdlibApi
    fun writeAllDataToDataFile() {
        val gson = GsonBuilder().setPrettyPrinting().create()
        val str: String = gson.toJson(getAllData())
        val path: Path = Paths.get(userConfig.dataFilePath)
        val strToBytes = str.toByteArray()
        Files.write(path, strToBytes)
    }
}
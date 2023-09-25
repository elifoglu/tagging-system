package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.AllData
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import org.springframework.stereotype.Component
import java.util.*

@Component
open class DataHolder {

    var data: AllData? = null

    fun addAllData(allData: AllData) {
        data = allData
    }

    fun getAllData() = data

    fun clearData() {
        data = null
    }

    fun addContent(content: Content) {
        val newList: ArrayList<Content> = ArrayList()
        newList.addAll(data!!.contents)
        newList.add(content)
        data = data!!.copy(contents = newList)
    }

    fun addTag(tag: Tag) {
        val newList: ArrayList<Tag> = ArrayList()
        newList.addAll(data!!.tags)
        newList.add(tag)
        data = data!!.copy(tags = newList)
    }

    fun deleteContent(id: String) {
        val deleted = data!!.contents.filter { it.contentId != id.toInt() }
        data = data!!.copy(contents = deleted)
    }

    fun deleteTag(id: String) {
        val deleted = data!!.tags.filter { it.tagId != id }
        data = data!!.copy(tags = deleted)
    }

    fun clearTags() {
        data = data!!.copy(tags = emptyList())
    }
}
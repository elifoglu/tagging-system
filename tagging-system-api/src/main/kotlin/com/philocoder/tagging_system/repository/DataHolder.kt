package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.AllData
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import org.springframework.stereotype.Component
import java.util.*

@Component
open class DataHolder {

    private var data: AllData? = null

    fun addAllData(allData: AllData) {
        data = allData
    }

    fun getAllData() = data!!

    fun addContent(content: Content) {
        val newList: ArrayList<Content> = ArrayList()
        newList.addAll(data!!.contents)
        newList.add(content)
        data = data!!.copy(contents = newList)
    }

    fun updateContent(content: Content) {
        val updatedContentList = data!!.contents
            .map { if (it.contentId == content.contentId) content else it }
        data = data!!.copy(contents = updatedContentList)
    }

    fun deleteContent(id: String) {
        val updatedContents = data!!.contents.map { if (it.contentId != id ) it else it.copy(isDeleted = true, lastModifiedAt = Calendar.getInstance().timeInMillis,) }
        data = data!!.copy(contents = updatedContents)
    }

    fun addTag(tag: Tag) {
        val newList: ArrayList<Tag> = ArrayList()
        newList.addAll(data!!.tags)
        newList.add(tag)
        data = data!!.copy(tags = newList)
    }

    fun updateTag(tag: Tag) {
        val updatedTagList = data!!.tags
            .map { if (it.tagId == tag.tagId) tag else it }
        data = data!!.copy(tags = updatedTagList)
    }

    fun deleteTag(id: String) {
        val updatedTags = data!!.tags.map { if (it.tagId != id ) it else it.copy(isDeleted = true, lastModifiedAt = Calendar.getInstance().timeInMillis,) }
        data = data!!.copy(tags = updatedTags)
    }
}
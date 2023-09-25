package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.PageUtil.getPage
import org.springframework.stereotype.Repository

@Repository
open class TagRepository(
    private val dataHolder: DataHolder
) {

    fun getAllTags(): List<Tag> {
        val entities = getEntities(1, 10000)
        return entities.sortedWith { a, b -> 1 } //there will be nothing such as "allTags", so this will be changed. 1 is dummy here
    }

    fun getEntities(): List<Tag> {
        return dataHolder.data!!.tags
    }

    fun findEntity(id: String): Tag? {
        val tags = dataHolder.data!!.tags
        return tags.find { it.tagId == id }
    }

    fun addEntity(id: String, it: Tag) {
        dataHolder.addTag(it)
    }

    fun deleteEntity(id: String) {
        dataHolder.deleteTag(id)
    }

    fun deleteAll() {
        dataHolder.clearTags()
    }

    fun getHomeTag(): String {
        return dataHolder.getAllData()!!.homeTagId
    }

    private fun getEntities(
        page: Int = 1,
        size: Int = 10000,
    ): List<Tag> {
        val tags = dataHolder.data!!.tags
        return getPage(tags, page, size)
    }
}

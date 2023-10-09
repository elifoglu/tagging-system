package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository

@Repository
open class TagService(
    private val dataHolder: DataHolder
) {

    fun getNotDeletedAllTags(): List<Tag> {
        val entities = getNotDeletedEntities()
        return entities.sortedWith { a, b -> 1 } //there will be nothing such as "allTags", so this will be changed. 1 is dummy here
    }

    private fun getEntities(): List<Tag> {
        return dataHolder.getAllData().tags
    }

    private fun getNotDeletedEntities(): List<Tag> {
        return getEntities().filter { !it.isDeleted }
    }

    fun findEntity(id: String): Tag? {
        return getEntities().find { it.tagId == id }
    }

    fun findExistingEntity(id: String): Tag? {
        return getNotDeletedEntities().find { it.tagId == id }
    }

    fun getHomeTag(): String {
        return dataHolder.getAllData().homeTagId
    }

    fun pruneDeletedOnes(tags: List<String>): List<String> {
        return tags
            .map { findEntity(it)!! }
            .filter { !it.isDeleted }
            .map { it.tagId }
    }
}

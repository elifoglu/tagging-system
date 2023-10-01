package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.service.UndoService
import org.springframework.stereotype.Repository
import java.util.*

@Repository
open class ContentRepository(
    private val dataHolder: DataHolder
) {

    private class ContentComparator : Comparator<Content> {
        override fun compare(o1: Content, o2: Content): Int {
            val result = o1.createdAt.compareTo(o2.createdAt)
            if (result != 0) {
                return result
            }
            return o1.contentId.compareTo(o2.contentId)
        }
    }

    private val contentComparator = ContentComparator()

    fun getContentsForTag(
        tag: Tag
    ): List<Content> {
        var entities = dataHolder.getAllData().contents
        entities = entities.filter { it.tags.contains(tag.tagId) }
        return entities.sortedWith(contentComparator).reversed()
    }

    fun getContentCount(
        tagName: String
    ): Int {
        var entities = dataHolder.getAllData().contents
        return entities.filter { it.tags.contains(tagName) }.count()
    }

    fun findEntity(id: String): Content? {
        val contents = dataHolder.getAllData().contents
        return contents.find { it.contentId == id }
    }

    fun getEntities(): List<Content> {
        return dataHolder.getAllData().contents
    }
}



package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
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
        var entities = dataHolder.data!!.contents
        entities = entities.filter { it.tags.contains(tag.tagId) }
        return entities.sortedWith(contentComparator).reversed()
    }

    fun getContentCount(
        tagName: String
    ): Int {
        var entities = dataHolder.data!!.contents
        return entities.filter { it.tags.contains(tagName) }.count()
    }

    fun findEntity(id: String): Content? {
        val contents = dataHolder.data!!.contents
        return contents.find { it.contentId == id }
    }

    fun getEntities(): List<Content> {
        return dataHolder.data!!.contents
    }

    fun addEntity(it: Content) {
        dataHolder.addContent(it)
    }

    fun updateEntity(it: Content) {
        dataHolder.updateContent(it)
    }

    fun deleteEntity(id: String) {
        dataHolder.deleteContent(id)
    }
}



package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.PageUtil.getPage
import org.springframework.stereotype.Repository
import java.util.*

@Repository
open class ContentRepository(
    private val dataHolder: DataHolder
) {

    private class ContentComparator : Comparator<Content> {
        override fun compare(o1: Content, o2: Content): Int {
            val result = o1.dateAsTimestamp.compareTo(o2.dateAsTimestamp)
            if (result != 0) {
                return result
            }
            return o1.contentId.compareTo(o2.contentId)
        }
    }

    private val contentComparator = ContentComparator()

    fun getContentsForTag(
        page: Int,
        size: Int,
        tag: Tag
    ): List<Content> {
        var entities = dataHolder.data!!.contents

        entities = entities.filter { it.tags.contains(tag.name) }

        entities = entities.sortedWith(contentComparator).reversed()

        return getPage(entities, page, size)
    }

    fun getContentCount(
        tagName: String
    ): Int {
        var entities = dataHolder.data!!.contents
        return entities.filter { it.tags.contains(tagName) }.count()
    }

    fun findEntity(id: String): Content? {
        val contents = dataHolder.data!!.contents
        return contents.find { it.contentId == id.toInt() }
    }

    fun getEntities(): List<Content> {
        return dataHolder.data!!.contents
    }

    fun getEntities(page: Int, size: Int): List<Content> {
        val contents = dataHolder.data!!.contents
        return getPage(contents, page, size)
    }

    fun addEntity(id: String, it: Content) {
        dataHolder.addContent(it)
    }

    fun deleteEntity(id: String) {
        dataHolder.deleteContent(id)
    }
}



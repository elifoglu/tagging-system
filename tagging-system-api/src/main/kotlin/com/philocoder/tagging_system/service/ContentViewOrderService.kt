package com.philocoder.tagging_system.service

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Service

@Service
open class ContentViewOrderService(
    private val contentService: ContentService,
    private val tagService: TagService,
    private val dataHolder: DataHolder
) {


    @ExperimentalStdlibApi
    fun updateContentViewOrderForCreatedContent(content: Content, rollbackMoment: Long) {
        val contentViewOrder: ArrayList<Tuple2<ContentID, TagID>> = ArrayList(dataHolder.getAllData().contentViewOrder)
        val contentIdTagIdDuosOfContent: List<Tuple2<ContentID, TagID>> = content.tags
            .mapNotNull { tagService.findEntity(it) }
            .filter { !it.isDeleted }
            .map { Tuple2(content.contentId, it.tagId) }

        contentViewOrder.addAll(contentIdTagIdDuosOfContent)
        dataHolder.updateContentViewOrderWith(contentViewOrder, rollbackMoment)
    }

    @ExperimentalStdlibApi
    fun updateContentViewOrderForUpdatedContent(
        previousVersionOfContent: Content,
        content: Content,
        rollbackMoment: Long
    ) {
        val newlyAddedTags: ArrayList<String> = ArrayList()
        val newlyRemovedTagsOfContent: ArrayList<String> = ArrayList()

        previousVersionOfContent.tags.forEach {
            if (!content.tags.contains(it)) {
                newlyRemovedTagsOfContent.add(it)
            }
        }

        content.tags.forEach {
            if (!previousVersionOfContent.tags.contains(it)) {
                newlyAddedTags.add(it)
            }
        }

        val contentViewOrder: ArrayList<Tuple2<ContentID, TagID>> = ArrayList(dataHolder.getAllData().contentViewOrder)

        contentViewOrder.removeAll(newlyRemovedTagsOfContent.map { Tuple2(content.contentId, it) })

        val newlyAddedTagsOfContent: List<Tag> = newlyAddedTags
            .mapNotNull { tagService.findEntity(it) }
            .filter { !it.isDeleted }

        contentViewOrder.addAll(newlyAddedTagsOfContent.map { Tuple2(content.contentId, it.tagId) })

        dataHolder.updateContentViewOrderWith(contentViewOrder, rollbackMoment)
    }

    fun updateContentViewOrderForDeletedContent(deletedContent: Content, rollbackMoment: Long) {
        val contentViewOrder: ArrayList<Tuple2<ContentID, TagID>> = ArrayList(dataHolder.getAllData().contentViewOrder)
        val contentIdTagIdDuosOfContent: List<Tuple2<ContentID, TagID>> = deletedContent.tags
            .mapNotNull { tagService.findEntity(it) }
            .filter { !it.isDeleted }
            .map { Tuple2(deletedContent.contentId, it.tagId) }

        contentViewOrder.removeAll(contentIdTagIdDuosOfContent)

        dataHolder.updateContentViewOrderWith(contentViewOrder, rollbackMoment)
    }

    fun updateContentViewOrderForDeletedTag(tagId: String, rollbackMoment: Long) {
        val tag = tagService.findEntity(tagId)!!
        val contentViewOrder: ArrayList<Tuple2<ContentID, TagID>> = ArrayList(dataHolder.getAllData().contentViewOrder)
        val allContentIdTagIdDuosOfTag = dataHolder.getAllData().contents
            .filter { !it.isDeleted }
            .filter { it.tags.contains(tagId) }
            .map { (Tuple2(it.contentId, tagId)) }
        contentViewOrder.removeAll(allContentIdTagIdDuosOfTag)
        dataHolder.updateContentViewOrderWith(contentViewOrder, rollbackMoment)
    }

}



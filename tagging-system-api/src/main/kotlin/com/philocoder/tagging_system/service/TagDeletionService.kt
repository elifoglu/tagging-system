package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Service
import java.util.*

@Service
class TagDeletionService(
    private val tagService: TagService,
    private val contentService: ContentService,
    private val contentViewOrderService: ContentViewOrderService,
    private val dataService: DataService,
    private val dataHolder: DataHolder
) {
    companion object {
        @ExperimentalStdlibApi
        val deleteOnlyTagFn: (String, TagDeletionService, ContentViewOrderService, Long) -> Unit =
            { tagId: String, service: TagDeletionService, contentViewOrderService: ContentViewOrderService, rollbackMoment: Long ->
                service.deleteTag(tagId, rollbackMoment)
                contentViewOrderService.updateContentViewOrderForDeletedTag(tagId, rollbackMoment)

            }

        @ExperimentalStdlibApi
        val deleteTagAndChildContentsFn: (String, TagDeletionService, ContentViewOrderService, Long) -> Unit =
            { tagId: String, service: TagDeletionService, contentViewOrderService: ContentViewOrderService, rollbackMoment: Long ->
                service.deleteTagAndChildContents(contentViewOrderService, tagId, rollbackMoment)
            }

        @ExperimentalStdlibApi
        val deleteTagWithAllDescendantsFn: (String, TagDeletionService, ContentViewOrderService, Long) -> Unit =
            { tagId: String, service: TagDeletionService, contentViewOrderService: ContentViewOrderService, rollbackMoment: Long ->
                service.deleteAllDescendantContents(contentViewOrderService, tagId, rollbackMoment)
                service.deleteTag(tagId, rollbackMoment)
                contentViewOrderService.updateContentViewOrderForDeletedTag(tagId, rollbackMoment)
            }

        @ExperimentalStdlibApi
        val tagDeletionStrategies: HashMap<String, (tagId: String, service: TagDeletionService, contentViewOrderService: ContentViewOrderService, rollbackMoment: Long) -> Unit> =
            hashMapOf(
                "only-tag" to deleteOnlyTagFn,
                "tag-and-child-contents" to deleteTagAndChildContentsFn,
                "tag-with-all-descendants" to deleteTagWithAllDescendantsFn
            )

        @ExperimentalStdlibApi
        fun isValidStrategy(str: String) = tagDeletionStrategies.keys.contains(str)

        @ExperimentalStdlibApi
        fun getStrategyFn(str: String): ((tagId: String, tagDeletionService: TagDeletionService, contentViewOrderService: ContentViewOrderService, rollbackMoment: Long) -> Unit) =
            tagDeletionStrategies[str]!!

    }

    @ExperimentalStdlibApi
    fun deleteTagWithStrategy(tagId: String, tagDeletionStrategy: String, rollbackMoment: Long): String {
        if (!isValidStrategy(tagDeletionStrategy)) {
            return "not-valid-strategy"
        }
        getStrategyFn(tagDeletionStrategy).invoke(tagId, this, contentViewOrderService, rollbackMoment)
        dataService.regenerateWholeData()
        return "done"
    }

    private fun deleteTag(tagId: String, rollbackMoment: Long) {
        dataHolder.deleteTag(tagId, rollbackMoment)
    }

    private fun deleteTagAndChildContents(
        contentViewOrderService: ContentViewOrderService,
        tagId: String,
        rollbackMoment: Long
    ) {
        val tag: Tag = tagService.findEntity(tagId)!!

        //Delete child contents
        contentService.getContentsForTag(tag)
            .filter { !it.isDeleted } //this is just to avoid deleting already deleted ones, because otherwise, lastModifiedDate field of content will be updated unnecessarily
            .forEach { it ->
                dataHolder.deleteContent(it.contentId, rollbackMoment)
                contentViewOrderService.updateContentViewOrderForDeletedContent(it, rollbackMoment)
            }

        //Delete tag itself
        dataHolder.deleteTag(tagId, rollbackMoment)
        contentViewOrderService.updateContentViewOrderForDeletedTag(tagId, rollbackMoment)
    }


    private fun deleteAllDescendantContents(
        contentViewOrderService: ContentViewOrderService,
        tagId: String,
        rollbackMoment: Long
    ) {
        val tag: Tag = tagService.findEntity(tagId)!!

        //We have to call this fn recursively to be able to delete all descendant contents
        tag.childTags
            .forEach { deleteAllDescendantContents(contentViewOrderService, it, rollbackMoment) }

        //Delete all contents recursively
        contentService.getContentsForTag(tag)
            .filter { !it.isDeleted } //this is just to avoid deleting already deleted ones, because otherwise, lastModifiedDate field of content will be updated unnecessarily
            .forEach {
                dataHolder.deleteContent(it.contentId, rollbackMoment)
                contentViewOrderService.updateContentViewOrderForDeletedContent(it, rollbackMoment)
            }
    }
}
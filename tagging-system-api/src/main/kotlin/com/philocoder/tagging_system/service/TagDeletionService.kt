package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Service
import java.util.*

@Service
class TagDeletionService(
    private val tagService: TagService,
    private val contentService: ContentService,
    private val dataService: DataService,
    private val dataHolder: DataHolder
) {
    companion object {
        @ExperimentalStdlibApi
        val deleteOnlyTagFn: (String, TagDeletionService, Long) -> Unit =
            { tagId: String, service: TagDeletionService, rollbackMoment: Long ->
                service.deleteTag(tagId, rollbackMoment)
            }

        @ExperimentalStdlibApi
        val deleteTagAndChildContentsFn: (String, TagDeletionService, Long) -> Unit =
            { tagId: String, service: TagDeletionService, rollbackMoment: Long ->
                service.deleteTagAndChildContents(tagId, rollbackMoment)
            }

        @ExperimentalStdlibApi
        val deleteTagWithAllDescendantsFn: (String, TagDeletionService, Long) -> Unit =
            { tagId: String, service: TagDeletionService, rollbackMoment: Long ->
                service.deleteAllDescendantContents(tagId, rollbackMoment)
                service.deleteTag(tagId, rollbackMoment)
            }

        @ExperimentalStdlibApi
        val tagDeletionStrategies: HashMap<String, (tagId: String, service: TagDeletionService, rollbackMoment: Long) -> Unit> =
            hashMapOf(
                "only-tag" to deleteOnlyTagFn,
                "tag-and-child-contents" to deleteTagAndChildContentsFn,
                "tag-with-all-descendants" to deleteTagWithAllDescendantsFn
            )

        @ExperimentalStdlibApi
        fun isValidStrategy(str: String) = tagDeletionStrategies.keys.contains(str)

        @ExperimentalStdlibApi
        fun getStrategyFn(str: String): ((tagId: String, tagDeletionService: TagDeletionService, rollbackMoment: Long) -> Unit) =
            tagDeletionStrategies[str]!!

    }

    @ExperimentalStdlibApi
    fun deleteTagWithStrategy(tagId: String, tagDeletionStrategy: String, rollbackMoment: Long): String {
        if (!isValidStrategy(tagDeletionStrategy)) {
            return "not-valid-strategy"
        }
        getStrategyFn(tagDeletionStrategy).invoke(tagId, this, rollbackMoment)
        dataService.regenerateWholeData()
        return "done"
    }

    private fun deleteTag(tagId: String, rollbackMoment: Long) {
        dataHolder.deleteTag(tagId, rollbackMoment)
    }

    private fun deleteTagAndChildContents(tagId: String, rollbackMoment: Long) {
        val tag: Tag = tagService.findEntity(tagId)!!

        //Delete child contents
        contentService.getContentsForTag(tag)
            .filter { !it.isDeleted } //this is just to avoid deleting already deleted ones, because otherwise, lastModifiedDate field of content will be updated unnecessarily
            .forEach { dataHolder.deleteContent(it.contentId, rollbackMoment) }

        //Delete tag itself
        dataHolder.deleteTag(tagId, rollbackMoment)

    }


    private fun deleteAllDescendantContents(tagId: String, rollbackMoment: Long) {
        val tag: Tag = tagService.findEntity(tagId)!!

        //We have to call this fn recursively to be able to delete all descendant contents
        tag.childTags
            .forEach { deleteAllDescendantContents(it, rollbackMoment) }

        //Delete all contents recursively
        contentService.getContentsForTag(tag)
            .filter { !it.isDeleted } //this is just to avoid deleting already deleted ones, because otherwise, lastModifiedDate field of content will be updated unnecessarily
            .forEach { dataHolder.deleteContent(it.contentId, rollbackMoment) }
    }
}
package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository
import org.springframework.stereotype.Service
import java.util.*

@Service
class TagDeletionService(
    private val tagRepository: TagRepository,
    private val contentRepository: ContentRepository,
    private val dataService: DataService
) {
    companion object {
        @ExperimentalStdlibApi
        val deleteOnlyTagFn: (String, TagDeletionService) -> Unit =
            { tagId: String, service: TagDeletionService ->
                service.deleteTag(tagId)
            }

        @ExperimentalStdlibApi
        val deleteTagAndChildContentsFn: (String, TagDeletionService) -> Unit =
            { tagId: String, service: TagDeletionService ->
                service.deleteTagAndChildContents(tagId)
            }

        @ExperimentalStdlibApi
        val deleteTagWithAllDescendantsFn: (String, TagDeletionService) -> Unit =
            { tagId: String, service: TagDeletionService ->
                service.deleteAllDescendantContents(tagId)
                service.deleteTag(tagId)
            }

        @ExperimentalStdlibApi
        val tagDeletionStrategies: HashMap<String, (tagId: String, service: TagDeletionService) -> Unit> =
            hashMapOf(
                "only-tag" to deleteOnlyTagFn,
                "tag-and-child-contents" to deleteTagAndChildContentsFn,
                "tag-with-all-descendants" to deleteTagWithAllDescendantsFn
            )

        @ExperimentalStdlibApi
        fun isValidStrategy(str: String) = tagDeletionStrategies.keys.contains(str)

        @ExperimentalStdlibApi
        fun getStrategyFn(str: String): ((tagId: String, tagDeletionService: TagDeletionService) -> Unit) =
            tagDeletionStrategies[str]!!

    }

    @ExperimentalStdlibApi
    fun deleteTagWithStrategy(tagId: String, tagDeletionStrategy: String): String {
        if (!isValidStrategy(tagDeletionStrategy)) {
            return "not-valid-strategy"
        }
        getStrategyFn(tagDeletionStrategy).invoke(tagId, this)
        dataService.regenerateWholeData()
        return "done"
    }

    private fun deleteTag(tagId: String) {
        tagRepository.deleteEntity(tagId)
    }

    private fun deleteTagAndChildContents(tagId: String) {
        val tag: Tag = tagRepository.findEntity(tagId)!!

        //Delete child contents
        contentRepository.getContentsForTag(tag)
            .filter { !it.isDeleted } //this is just to avoid deleting already deleted ones, because otherwise, lastModifiedDate field of content will be updated unnecessarily
            .forEach { contentRepository.deleteEntity(it.contentId) }

        //Delete tag itself
        tagRepository.deleteEntity(tagId)

    }


    private fun deleteAllDescendantContents(tagId: String) {
        val tag: Tag = tagRepository.findEntity(tagId)!!

        //We have to call this fn recursively to be able to delete all descendant contents
        tag.childTags
            .forEach { deleteAllDescendantContents(it)  }

        //Delete all contents recursively
        contentRepository.getContentsForTag(tag)
            .filter { !it.isDeleted } //this is just to avoid deleting already deleted ones, because otherwise, lastModifiedDate field of content will be updated unnecessarily
            .forEach { contentRepository.deleteEntity(it.contentId) }
    }
}
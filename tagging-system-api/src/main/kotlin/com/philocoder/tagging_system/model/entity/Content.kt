package com.philocoder.tagging_system.model.entity

import arrow.core.extensions.list.foldable.exists
import arrow.core.extensions.list.foldable.forAll
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.request.CreateContentRequest
import com.philocoder.tagging_system.model.request.UpdateContentRequest
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository
import java.util.*

data class Content(
    val title: String?,
    val contentId: ContentID,
    val content: String?,
    val tags: List<String>,
    val dateAsTimestamp: Long,
    val textToSearchOn: String?
) {

    companion object {
        fun createIfValidForCreation(
            req: CreateContentRequest,
            contentRepository: ContentRepository,
            tagRepository: TagRepository
        ): Content? {
            if (req.id.isEmpty()
                || req.text.isEmpty()
                || req.tags.isEmpty()
            ) {
                return null
            }

            //check if every entered tag name exists
            val tagNames = req.tags.split(",")
            val allTags: List<Tag> = tagRepository.getEntities()
            val allTagNamesExists = tagNames.forAll { tagName ->
                allTags.exists { it.name == tagName }
            }
            if (!allTagNamesExists) {
                return null
            }

            //check if content with specified id already exists
            val allContents = contentRepository.getEntities()
            if (
                allContents.exists { it.contentId == req.id.toInt() }
            ) {
                return null
            }


            return Content(
                title = if (req.title.isNullOrEmpty()) null else req.title,
                contentId = req.id.toInt(),
                content = req.text,
                tags = tagNames,
                dateAsTimestamp = Calendar.getInstance().timeInMillis,
                textToSearchOn = null
            )
        }

        fun createIfValidForUpdate(
            contentId: ContentID,
            req: UpdateContentRequest,
            contentRepository: ContentRepository,
            tagRepository: TagRepository
        ): Content? {
            if (contentId.toString().isEmpty()
                || req.text.isEmpty()
                || req.tags.isEmpty()
            ) {
                return null
            }

            //check if every entered tag name exists
            val tagNames = req.tags.split(",")
            val allTags = tagRepository.getEntities()
            val allTagNamesExists = tagNames.forAll { tagName ->
                allTags.exists { it.name == tagName }
            }
            if (!allTagNamesExists) {
                return null
            }

            //check if content with specified id not exists
            val existingContent: Content = contentRepository.findEntity(contentId.toString())
                ?: return null

            return Content(
                title = if (req.title.isNullOrEmpty()) null else req.title,
                contentId = contentId,
                content = req.text,
                tags = tagNames,
                dateAsTimestamp = existingContent.dateAsTimestamp,
                textToSearchOn = existingContent.textToSearchOn
            )
        }
    }
}
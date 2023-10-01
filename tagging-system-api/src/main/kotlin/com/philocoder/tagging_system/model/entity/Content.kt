package com.philocoder.tagging_system.model.entity

import arrow.core.Either
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.request.CreateContentRequest
import com.philocoder.tagging_system.model.request.UpdateContentRequest
import com.philocoder.tagging_system.service.ContentService
import com.philocoder.tagging_system.util.DateUtils.now
import org.apache.commons.lang3.RandomStringUtils

data class Content(
    val contentId: String,
    val title: String?,
    val content: String?,
    val tags: List<String>,
    val createdAt: Long,
    val lastModifiedAt: Long,
    val isDeleted: Boolean
) {

    companion object {
        @ExperimentalStdlibApi
        fun createIfValidForCreation(
            req: CreateContentRequest,
            service: ContentService,
        ): Content? {
            var uniqueContentId: String
            do {
                uniqueContentId = RandomStringUtils.randomAlphanumeric(4).lowercase()
            } while (service.findEntity(uniqueContentId) != null)

            if (req.text == "")
                return null

            return Content(
                title = if (req.title.isNullOrEmpty()) null else req.title,
                contentId = uniqueContentId,
                content = req.text,
                tags = req.tags,
                createdAt = now(),
                lastModifiedAt = now(),
                isDeleted = false
            )
        }

        fun createIfValidForUpdate(
            contentId: ContentID,
            req: UpdateContentRequest,
            service: ContentService,
        ): Content? {
            if (req.text.isEmpty()) {
                return null
            }

            //check if content with specified id not exists
            val existingContent: Content = service.findEntity(contentId)
                ?: return null

            return Content(
                title = if (req.title.isNullOrEmpty()) null else req.title,
                contentId = contentId,
                content = req.text,
                tags = req.tags,
                createdAt = existingContent.createdAt,
                lastModifiedAt = now(),
                isDeleted = existingContent.isDeleted
            )
        }

        fun returnItsIdIfValidForDelete(
            contentId: ContentID,
            service: ContentService,
        ): Either<String, ContentID> {
            //check if content with specified id exists
            val existingContent: Content = service.findEntity(contentId)
                ?: return Either.left("non-existing-content")

            return Either.right(existingContent.contentId)
        }
    }
}
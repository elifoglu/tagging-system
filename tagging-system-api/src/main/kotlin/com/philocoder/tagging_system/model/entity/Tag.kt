package com.philocoder.tagging_system.model.entity

import arrow.core.Either
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.request.CreateTagRequest
import com.philocoder.tagging_system.model.request.DeleteTagRequest
import com.philocoder.tagging_system.model.request.TagWithoutChildTags
import com.philocoder.tagging_system.model.request.UpdateTagRequest
import com.philocoder.tagging_system.service.TagService
import com.philocoder.tagging_system.service.DataService
import com.philocoder.tagging_system.service.TagDeletionService
import com.philocoder.tagging_system.util.DateUtils.now
import org.apache.commons.lang3.RandomStringUtils
import java.util.*

data class Tag(
    val tagId: String,
    val name: String,
    val parentTags: List<String>,
    val childTags: List<String>,
    val description: String,
    val createdAt: Long,
    val lastModifiedAt: Long,
    val isDeleted: Boolean
) {

    @kotlin.ExperimentalStdlibApi
    companion object {
        fun createIfValidForCreation(
            req: CreateTagRequest,
            service: TagService
        ): Tag? {
            if (req.name.isEmpty())
                return null

            var uniqueTagId: String
            do {
                uniqueTagId = RandomStringUtils.randomAlphanumeric(4).lowercase()
            } while (service.findEntity(uniqueTagId) != null)

            return Tag(
                tagId = uniqueTagId,
                name = req.name,
                parentTags = req.parentTags,
                childTags = Collections.emptyList(),
                description = req.description,
                createdAt = now(),
                lastModifiedAt = now(),
                isDeleted = false
            )
        }

        fun createIfValidForUpdate(
            tagId: String,
            req: UpdateTagRequest,
            service: TagService
        ): Tag? {
            if (req.name.isEmpty())
                return null

            val tag: Tag = service.findEntity(tagId)!!

            return tag.copy(
                name = req.name,
                description = req.description,
                parentTags = req.parentTags,
                lastModifiedAt = now()
            )
        }

        fun returnItsIdIfValidForDelete(
            tagId: String,
            req: DeleteTagRequest,
            service: TagService,
            dataService: DataService
        ): Either<String, TagID> {
            if (!TagDeletionService.isValidStrategy(req.tagDeletionStrategy))
                return Either.left("non-existing-tag-deletion-strategy")

            val existingTag: Tag = service.findEntity(tagId)
                ?: return Either.left("non-existing-content")

            if (dataService.getAllData()!!.homeTagId == tagId)
                return Either.left("cannot-delete-home-tag")

            return Either.right(existingTag.tagId)
        }

        fun createWith(t: TagWithoutChildTags, parentToChildTagMap: HashMap<String, ArrayList<String>>): Tag {
            return Tag(
                tagId = t.tagId,
                name = t.name,
                parentTags = t.parentTags,
                childTags = parentToChildTagMap[t.tagId]!!,
                description = t.description,
                createdAt = t.createdAt,
                lastModifiedAt = t.lastModifiedAt,
                isDeleted = t.isDeleted
            )
        }

        fun toWithoutChild(t: Tag): TagWithoutChildTags {
            return TagWithoutChildTags(
                tagId = t.tagId,
                name = t.name,
                parentTags = t.parentTags,
                description = t.description,
                createdAt = t.createdAt,
                lastModifiedAt = t.lastModifiedAt,
                isDeleted = t.isDeleted
            )
        }

        fun onlyExistingChildTags(tag: Tag, service: TagService): List<String> =
            service.pruneDeletedOnes(tag.childTags)

    }
}
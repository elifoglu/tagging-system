package com.philocoder.tagging_system.model.entity

import com.philocoder.tagging_system.model.request.CreateTagRequest
import com.philocoder.tagging_system.model.request.TagWithoutChildTags
import com.philocoder.tagging_system.model.request.UpdateTagRequest
import com.philocoder.tagging_system.repository.TagRepository
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
            repository: TagRepository
        ): Tag? {
            if (req.name.isEmpty())
                return null

            var uniqueTagId: String
            do {
                uniqueTagId = RandomStringUtils.randomAlphanumeric(4).lowercase()
            } while ( repository.findEntity(uniqueTagId) != null )

            return Tag(
                tagId = uniqueTagId,
                name = req.name,
                parentTags = req.parentTags,
                childTags = Collections.emptyList(),
                description = req.description,
                createdAt = Calendar.getInstance().timeInMillis,
                lastModifiedAt = Calendar.getInstance().timeInMillis,
                isDeleted = false
            )
        }

        fun createIfValidForUpdate(
            tagId: String,
            req: UpdateTagRequest,
            repository: TagRepository
        ): Tag? {
            if (req.name.isEmpty())
                return null

            val tag: Tag = repository.findEntity(tagId)!!

            return tag.copy(
                name = req.name,
                description = req.description,
                parentTags = req.parentTags,
                lastModifiedAt = Calendar.getInstance().timeInMillis
            )
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
                isDeleted = false
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
    }
}
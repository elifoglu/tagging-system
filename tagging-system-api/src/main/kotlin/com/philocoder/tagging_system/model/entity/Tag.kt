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
    val infoContentId: Int?
) {

    @kotlin.ExperimentalStdlibApi
    companion object {
        fun createIfValidForCreation(
            req: CreateTagRequest,
            repository: TagRepository
        ): Tag? {
            var uniqueTagId: String
            do {
                uniqueTagId = RandomStringUtils.randomAlphanumeric(4).lowercase()
            } while ( repository.findEntity(uniqueTagId) != null )

            return Tag(
                tagId = uniqueTagId,
                name = req.name,
                parentTags = Collections.emptyList(),
                childTags = Collections.emptyList(),
                infoContentId = null
            )
        }

        fun createIfValidForUpdate(
            tagId: String,
            req: UpdateTagRequest,
            repository: TagRepository
        ): Tag? {
            val tag: Tag = repository.findEntity(tagId)!!

            return tag.copy(
                infoContentId = if(req.infoContentId.isEmpty()) null else req.infoContentId.toInt()
            )
        }

        fun createWith(t: TagWithoutChildTags, parentToChildTagMap: HashMap<String, ArrayList<String>>): Tag {
            return Tag(
                tagId = t.tagId,
                name = t.name,
                parentTags = t.parentTags,
                childTags = parentToChildTagMap[t.tagId]!!,
                infoContentId = t.infoContentId
            )
        }

        fun toWithoutChild(t: Tag): TagWithoutChildTags {
            return TagWithoutChildTags(
                tagId = t.tagId,
                name = t.name,
                parentTags = t.parentTags,
                infoContentId = t.infoContentId
            )
        }
    }
}
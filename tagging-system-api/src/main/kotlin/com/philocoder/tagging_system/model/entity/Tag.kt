package com.philocoder.tagging_system.model.entity

import arrow.core.extensions.list.foldable.exists
import com.philocoder.tagging_system.model.request.CreateTagRequest
import com.philocoder.tagging_system.model.request.UpdateTagRequest
import com.philocoder.tagging_system.repository.TagRepository

data class Tag(
    val tagId: String,
    val name: String,
    val infoContentId: Int?
) {

    companion object {
        fun createIfValidForCreation(
            req: CreateTagRequest,
            repository: TagRepository
        ): Tag? {
            if (req.tagId.isEmpty()
                || req.name.isEmpty()
            ) {
                return null
            }

            //check if tag with specified id already exists
            val allTags: List<Tag> = repository.getEntities()
            if (
                allTags.exists { it.tagId == req.tagId }
            ) {
                return null
            }

            return Tag(
                tagId = req.tagId,
                name = req.name,
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
    }
}
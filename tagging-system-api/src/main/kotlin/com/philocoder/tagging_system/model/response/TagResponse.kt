package com.philocoder.tagging_system.model.response

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository

data class TagResponse(
    val tagId: String,
    val name: String,
    val parentTags: List<String>,
    val childTags: List<String>,
    val contentCount: Int,
    val description: String,
    val createdAt: String,
    val lastModifiedAt: String,
    val isDeleted: Boolean
) {

    companion object {
        fun create(
            tag: Tag,
            tagRepository: TagRepository,
            contentRepository: ContentRepository
        ): TagResponse =
            TagResponse(
                tagId = tag.tagId,
                name = tag.name,
                parentTags = tagRepository.pruneDeletedOnes(tag.parentTags) ,
                childTags = tagRepository.pruneDeletedOnes(tag.childTags),
                contentCount = contentRepository.getContentCount(tag.name),
                description = tag.description,
                createdAt = tag.createdAt.toString(),
                lastModifiedAt = tag.lastModifiedAt.toString(),
                isDeleted = tag.isDeleted
            )
    }
}
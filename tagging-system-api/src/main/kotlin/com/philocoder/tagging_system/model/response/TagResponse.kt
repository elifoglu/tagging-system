package com.philocoder.tagging_system.model.response

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.ContentRepository

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
            repo: ContentRepository
        ): TagResponse =
            TagResponse(
                tagId = tag.tagId,
                name = tag.name,
                parentTags = tag.parentTags,
                childTags = tag.childTags,
                contentCount = repo.getContentCount(tag.name),
                description = tag.description,
                createdAt = tag.createdAt.toString(),
                lastModifiedAt = tag.lastModifiedAt.toString(),
                isDeleted = tag.isDeleted
            )
    }
}
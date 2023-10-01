package com.philocoder.tagging_system.model.response

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.service.ContentService
import com.philocoder.tagging_system.service.TagService

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
            tagService: TagService,
            contentService: ContentService
        ): TagResponse =
            TagResponse(
                tagId = tag.tagId,
                name = tag.name,
                parentTags = tagService.pruneDeletedOnes(tag.parentTags) ,
                childTags = tagService.pruneDeletedOnes(tag.childTags),
                contentCount = contentService.getContentCount(tag.name),
                description = tag.description,
                createdAt = tag.createdAt.toString(),
                lastModifiedAt = tag.lastModifiedAt.toString(),
                isDeleted = tag.isDeleted
            )
    }
}
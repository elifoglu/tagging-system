package com.philocoder.tagging_system.model.response

import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.entity.Content

data class ContentResponse(
    val title: String?,
    val contentId: ContentID,
    val content: String?,
    val tagIds: List<TagID>,
    val tagIdOfCurrentTextPart: TagID?,
    val createdAt: String,
    val lastModifiedAt: String,
    val isDeleted: Boolean
) {

    companion object {
        fun createWith(content: Content, tagIdOfCurrentTextPart: TagID?): ContentResponse {
            return ContentResponse(
                title = content.title,
                contentId = content.contentId,
                content = content.content,
                tagIds = content.tags,
                tagIdOfCurrentTextPart = tagIdOfCurrentTextPart,
                createdAt = content.createdAt.toString(),
                lastModifiedAt = content.lastModifiedAt.toString(),
                isDeleted = content.isDeleted
            )
        }

    }
}
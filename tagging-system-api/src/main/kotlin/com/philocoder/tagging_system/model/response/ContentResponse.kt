package com.philocoder.tagging_system.model.response

import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.entity.Content

data class ContentResponse(
    val title: String?,
    val dateAsTimestamp: String,
    val contentId: ContentID,
    val content: String?,
    val tags: List<String>
) {

    companion object {
        fun createWith(content: Content): ContentResponse {
            return ContentResponse(
                title = content.title,
                dateAsTimestamp = content.dateAsTimestamp.toString(),
                contentId = content.contentId,
                content = content.content,
                tags = content.tags
            )
        }

    }
}
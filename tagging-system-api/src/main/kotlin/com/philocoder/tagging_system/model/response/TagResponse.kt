package com.philocoder.tagging_system.model.response

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.ContentRepository

data class TagResponse(
    val tagId: String,
    val name: String,
    val contentCount: Int,
    val infoContentId: Int?
) {

    companion object {
        fun create(
            tag: Tag,
            repo: ContentRepository
        ): TagResponse =
            TagResponse(
                tagId = tag.tagId,
                name = tag.name,
                contentCount = repo.getContentCount(tag.name),
                infoContentId = tag.infoContentId
            )

        fun createForAllContentsMode(
            tag: Tag,
            repo: ContentRepository
        ): TagResponse =
            create(tag, repo)

    }
}
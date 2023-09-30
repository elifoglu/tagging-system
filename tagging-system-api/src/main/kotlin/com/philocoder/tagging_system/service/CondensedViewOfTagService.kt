package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.TagResponse
import com.philocoder.tagging_system.model.response.TagTextResponse
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository
import org.springframework.stereotype.Service

@Service
class CondensedViewOfTagService(
    private val repository: ContentRepository,
    private val tagRepository: TagRepository
) {

    fun getTagTextResponse(tag: Tag): TagTextResponse {
        var allRelatedTagsToCreateCondensedText = ArrayList<String>()
        rep(tag.tagId, allRelatedTagsToCreateCondensedText)

        var tagTextParts = ArrayList<TagTextResponse.TagTextPart>()
        allRelatedTagsToCreateCondensedText.forEach { tagId ->
            val tag: Tag = tagRepository.findEntity(tagId)!!
            val contentResponses: List<ContentResponse> = repository
                .getContentsForTag(tag)
                .filter { !it.isDeleted }
                .map { ContentResponse.createWith(it) }
            tagTextParts.add(TagTextResponse.TagTextPart(TagResponse.create(tag, tagRepository, repository), contentResponses))
        }

        return TagTextResponse(tagTextParts)
    }

    private fun rep(
        tagId: String,
        allRelatedTagsToCreateCondensedText: ArrayList<String>
    ) {
        val tag: Tag = tagRepository.findEntity(tagId)!!
        if (!allRelatedTagsToCreateCondensedText.contains(tag.tagId)) {
            allRelatedTagsToCreateCondensedText.add(tag.tagId)
        }
        tag.childTags
            .filter { !allRelatedTagsToCreateCondensedText.contains(it) }
            .forEach { rep(it, allRelatedTagsToCreateCondensedText) }
    }

}
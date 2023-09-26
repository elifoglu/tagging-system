package com.philocoder.tagging_system.service

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository
import org.springframework.stereotype.Service

@Service
class CondensedViewOfTagService(
    private val repository: ContentRepository,
    private val tagRepository: TagRepository
) {

    fun getCondensedTextOfTag(tag: Tag): String {
        var allRelatedTagsToCreateCondensedText = ArrayList<String>()
        rep(tag.tagId, allRelatedTagsToCreateCondensedText)

        var tagToContentsMap = ArrayList<Tuple2<Tag, List<ContentResponse>>>()
        allRelatedTagsToCreateCondensedText.forEach { tagId ->
            val tag: Tag = tagRepository.findEntity(tagId)!!
            val contentResponses: List<ContentResponse> = repository
                .getContentsForTag(tag)
                .map { ContentResponse.createWith(it) }
            tagToContentsMap.add(Tuple2(tag, contentResponses))
        }

        return createText(tag, tagToContentsMap)
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


    private fun createText(baseTag: Tag, tagToContentsMap: ArrayList<Tuple2<Tag, List<ContentResponse>>>): String {
        var text = ""
        tagToContentsMap.forEach { (tag: Tag, contents: List<ContentResponse>) ->
            if(tag.tagId != baseTag.tagId && contents.isNotEmpty()) {
                text += "[#${tag.name}](/tags/${tag.tagId})  \n"
            }
            if(contents.isNotEmpty()) {
                contents.forEach { content ->
                    text += "[•](/contents/${content.contentId}) " + content.content!! + "  \n"
                }
                text = text.dropLast(3) //to remove the latest added, unwanted "  \n" chars
                text += "\n\n"
            }
        }
        return text
    }

}
package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.ContentsOfTagRequest
import com.philocoder.tagging_system.model.request.SearchContentRequest
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.model.response.TagResponse
import com.philocoder.tagging_system.model.response.TagTextResponse
import com.philocoder.tagging_system.repository.DataHolder
import org.apache.commons.lang3.StringUtils
import org.springframework.stereotype.Repository
import java.util.*

@Repository
open class ContentService(
    private val tagService: TagService,
    private val dataHolder: DataHolder
) {


    @ExperimentalStdlibApi
    fun getContentsResponse(req: ContentsOfTagRequest): TagTextResponse {
        val tagIdToUse = if (req.tagId == "tagging-system-home-page") tagService.getHomeTag() else req.tagId
        val tag: Tag = tagService.findExistingEntity(tagIdToUse)
            ?: return TagTextResponse(Collections.emptyList())
        return getTagTextResponse(tag)
    }

    fun getContentsResponseByKeywordSearch(
        req: SearchContentRequest
    ): SearchContentResponse {
        val contents: List<ContentResponse> =
            dataHolder.getAllData().contents
                .filter {
                    StringUtils.containsIgnoreCase(it.content!!, req.keyword)
                            || StringUtils.containsIgnoreCase(it.title, req.keyword)
                }
                .filter { it.tags.count() > 0 } // hidden contents have no tags and we don't want to show them on search result
                .map { ContentResponse.createWith(it) }
                .sortedBy { it.createdAt }
                .reversed()
        return SearchContentResponse(contents)
    }

    private class ContentComparator : Comparator<Content> {
        override fun compare(o1: Content, o2: Content): Int {
            val result = o1.createdAt.compareTo(o2.createdAt)
            if (result != 0) {
                return result
            }
            return o1.contentId.compareTo(o2.contentId)
        }
    }

    private val contentComparator = ContentComparator()

    @ExperimentalStdlibApi
    fun getTagTextResponse(tag: Tag): TagTextResponse {
        var allRelatedTagsToCreateCondensedText = ArrayList<String>()
        rep(tag.tagId, allRelatedTagsToCreateCondensedText)

        var tagTextParts = ArrayList<TagTextResponse.TagTextPart>()
        allRelatedTagsToCreateCondensedText.forEach { tagId ->
            val tag: Tag = tagService.findEntity(tagId)!!
            val contentResponses: List<ContentResponse> =
                getContentsForTag(tag)
                    .filter { !it.isDeleted }
                    .map { ContentResponse.createWith(it) }
                    .sortedWith { a, b -> (a.createdAt.toLong() - b.createdAt.toLong()).toInt() }
            tagTextParts.add(
                TagTextResponse.TagTextPart(
                    TagResponse.create(tag, tagService, this),
                    contentResponses
                )
            )
        }

        return TagTextResponse(tagTextParts)
    }

    @ExperimentalStdlibApi
    private fun rep(
        tagId: String,
        allRelatedTagsToCreateCondensedText: ArrayList<String>
    ) {
        val tag: Tag = tagService.findExistingEntity(tagId) ?: return
        if (!allRelatedTagsToCreateCondensedText.contains(tag.tagId)) {
            allRelatedTagsToCreateCondensedText.add(tag.tagId)
        }
        Tag.onlyExistingChildTags(tag, tagService)
            .filter { !allRelatedTagsToCreateCondensedText.contains(it) }
            .forEach { rep(it, allRelatedTagsToCreateCondensedText) }
    }

    fun getContentsForTag(
        tag: Tag
    ): List<Content> {
        var entities = dataHolder.getAllData().contents
        entities = entities.filter { it.tags.contains(tag.tagId) }
        return entities.sortedWith(contentComparator).reversed()
    }

    fun getContentCount(
        tagName: String
    ): Int {
        var entities = dataHolder.getAllData().contents
        return entities.filter { it.tags.contains(tagName) }.count()
    }

    fun findEntity(id: String): Content? {
        val contents = dataHolder.getAllData().contents
        return contents.find { it.contentId == id }
    }
}



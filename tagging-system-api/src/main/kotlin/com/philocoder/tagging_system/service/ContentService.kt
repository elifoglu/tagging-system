package com.philocoder.tagging_system.service

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
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
import kotlin.collections.ArrayList

@Repository
open class ContentService(
    private val tagService: TagService,
    private val dataHolder: DataHolder
) {


    @ExperimentalStdlibApi
    fun getContentsResponse(req: ContentsOfTagRequest): TagTextResponse {
        val tagIdToUse = if (req.tagId == "tagging-system-home-page") tagService.getHomeTag() else req.tagId
        val tag: Tag = tagService.findExistingEntity(tagIdToUse)
            ?: return TagTextResponse.empty
        return TagTextResponse(
            textPartsForGroupView = getTagTextPartsForGroupView(tag),
            textPartsForDistinctGroupView = getTagTextPartsForDistinctGroupView(tag),
            textPartsForLineView = getTagTextPartsForLineView(tag),
        )
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
    fun getTagTextPartsForGroupView(tag: Tag): List<TagTextResponse.TagTextPart> {
        return getTagTextParts(tag)
    }

    @ExperimentalStdlibApi
    fun getTagTextPartsForDistinctGroupView(tag: Tag): List<TagTextResponse.TagTextPart> {
        val tagTextPartsForGroupView = getTagTextParts(tag)
        var tagTextPartsForDistinctGroupView = ArrayList<Tuple2<TagResponse, ArrayList<ContentResponse>>>()

        val alreadyAddedContents = ArrayList<ContentID>()
        tagTextPartsForGroupView.forEach { it: TagTextResponse.TagTextPart ->
            val initialTagTextPartToAdd: Tuple2<TagResponse, ArrayList<ContentResponse>> =
                Tuple2(it.tag, ArrayList<ContentResponse>())
            tagTextPartsForDistinctGroupView.add(initialTagTextPartToAdd)

            val indexOfCurrentTagTextPart = tagTextPartsForDistinctGroupView.indexOf(initialTagTextPartToAdd)

            it.contents.forEach { content ->
                if (!alreadyAddedContents.contains(content.contentId)) {
                    tagTextPartsForDistinctGroupView[indexOfCurrentTagTextPart].b.add(content)
                    alreadyAddedContents.add(content.contentId)
                }
            }
        }

        val tagTextPartsWithDistinctContentsForDistinctGroupView = ArrayList<TagTextResponse.TagTextPart>()
        tagTextPartsForDistinctGroupView.forEach { (a: TagResponse, b: ArrayList<ContentResponse>) ->
            tagTextPartsWithDistinctContentsForDistinctGroupView.add(TagTextResponse.TagTextPart(a, b))
        }
        return tagTextPartsWithDistinctContentsForDistinctGroupView
    }

    @ExperimentalStdlibApi
    fun getTagTextPartsForLineView(tag: Tag): List<TagTextResponse.TagTextPart> {
        //I simply do this to use same TagTextPart model too in LineView: I get contents from DistinctGroupView data and flatten them into the base tag (which is always the first one on the TagTextPart lists)
        val baseTag: TagResponse = getTagTextPartsForDistinctGroupView(tag).get(0).tag
        val allContentResponsesFlatten: List<ContentResponse> =
            getTagTextPartsForDistinctGroupView(tag).flatMap { it.contents }
        return Collections.singletonList(TagTextResponse.TagTextPart(baseTag, allContentResponsesFlatten))
    }

    @ExperimentalStdlibApi
    fun getTagTextParts(tag: Tag): List<TagTextResponse.TagTextPart> {
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

        return tagTextParts
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



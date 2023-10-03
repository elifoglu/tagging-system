package com.philocoder.tagging_system.service

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.SearchContentRequest
import com.philocoder.tagging_system.model.request.TagTextRequest
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.model.response.TagResponse
import com.philocoder.tagging_system.model.response.TagTextResponse
import com.philocoder.tagging_system.repository.DataHolder
import org.apache.commons.lang3.StringUtils
import org.springframework.stereotype.Service
import java.util.*
import kotlin.collections.ArrayList

@Service
open class ContentService(
    private val tagService: TagService,
    private val dataHolder: DataHolder
) {


    @ExperimentalStdlibApi
    fun getTagTextResponse(req: TagTextRequest): TagTextResponse {
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
        if (req.keyword.length < 3) {
            return SearchContentResponse.empty
        }
        val contents: List<ContentResponse> =
            dataHolder.getAllData().contents
                .filter {
                    StringUtils.containsIgnoreCase(it.content!!, req.keyword)
                            || StringUtils.containsIgnoreCase(it.title, req.keyword)
                }
                .filter { !it.isDeleted }
                .map { ContentResponse.createWith(it, null) }
                .sortedBy { it.lastModifiedAt }
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
            tagTextPartsWithDistinctContentsForDistinctGroupView.add(
                TagTextResponse.TagTextPart(
                    a,
                    ArrayList(b.filter { it.content != null && it.content != "" })
                )
            )
        }
        return tagTextPartsWithDistinctContentsForDistinctGroupView
    }

    @ExperimentalStdlibApi
    fun getTagTextPartsForLineView(tag: Tag): List<TagTextResponse.TagTextPart> {
        val baseTag: TagResponse = TagResponse.create(tag, tagService, this)

        val allTagsUnderBaseTag = getTagTextPartsForDistinctGroupView(tag)
            .map { it.tag.tagId }

        val currentContentViewOrderForLineView: List<ContentResponse> =
            dataHolder.getAllData().contentViewOrder
                .filter { allTagsUnderBaseTag.contains(it.b) }
                .distinctBy { it.a }
                .map { ContentResponse.createWith(findEntity(it.a)!!, it.b) }
                .filter { it.content != null && it.content != "" }

        return Collections.singletonList(
            TagTextResponse.TagTextPart(
                baseTag,
                ArrayList(currentContentViewOrderForLineView)
            )
        )
    }

    @ExperimentalStdlibApi
    fun getTagTextParts(tag: Tag): List<TagTextResponse.TagTextPart> {
        val currentOrder = dataHolder.getAllData().contentViewOrder
        val tagTextParts: ArrayList<TagTextResponse.TagTextPart> = arrayListOf<TagTextResponse.TagTextPart>()
        currentOrder.forEach { (contentId, tagId) ->
            var tagTextPart: TagTextResponse.TagTextPart? = tagTextParts.find { it.tag.tagId == tagId }
            if (tagTextPart == null) {
                val tagResponse = TagResponse.create(tagService.findEntity(tagId)!!, tagService, this)
                tagTextPart = TagTextResponse.TagTextPart(tagResponse, arrayListOf())
                tagTextParts.add(tagTextPart)
            }
            tagTextPart.contents.add(ContentResponse.createWith(findEntity(contentId)!!, tagId))
        }

        val tagTextPartsButProperlyOrdered: java.util.ArrayList<TagTextResponse.TagTextPart> = ArrayList()

        val properOrderOfDescendantTagsOfTagTextParts =
            getProperOrderOfDescendantTags(tag)
                .filter { tagId -> tagTextParts.any { it.tag.tagId == tagId } }

        properOrderOfDescendantTagsOfTagTextParts
            .forEach { tagId ->
                tagTextPartsButProperlyOrdered.add(tagTextParts.find { it.tag.tagId == tagId }!!)
            }
        return tagTextPartsButProperlyOrdered
    }

    @ExperimentalStdlibApi
    fun getProperOrderOfDescendantTags(tag: Tag): ArrayList<TagID> {
        var allRelatedTagsToCreateCondensedText = ArrayList<String>()
        rep(tag.tagId, allRelatedTagsToCreateCondensedText)
        return allRelatedTagsToCreateCondensedText
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



package com.philocoder.tagging_system.service

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.ContentRefData
import com.philocoder.tagging_system.model.entity.Ref
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.ContentsOfTagRequest
import com.philocoder.tagging_system.model.request.SearchContentRequest
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.ContentsResponse
import com.philocoder.tagging_system.model.entity.GraphData
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.repository.TagRepository
import org.apache.commons.lang3.StringUtils
import org.springframework.stereotype.Service

@Service
class ContentService(
    private val repository: ContentRepository,
    private val tagRepository: TagRepository,
    private val dataHolder: DataHolder
) {

    fun getContentsResponse(req: ContentsOfTagRequest): ContentsResponse {
        val tag: Tag = tagRepository.findEntity(req.tagId)
            ?: return ContentsResponse.empty
        val contentResponses = repository
            .getContentsForTag(req.page, req.size, tag)
            .map { ContentResponse.createWith(it, repository, this) }
        val contentCount =
            repository.getContentCount(tag.name)
        val totalPageCount =
            if (contentCount % req.size == 0) contentCount / req.size else (contentCount / req.size) + 1
        return ContentsResponse(totalPageCount, contentResponses)
    }

    fun createWholeGraphData(allContents: List<Content>): GraphData {
        val refTuplesIncludingContentIds: List<ContentRefData> =
            allContents
                .mapNotNull {
                    it.refs?.map { ref -> ContentRefData(it.contentId, ref, "dummy") }
                }
                .flatten()
        return getGraphDataResponseViaContentRefDataList(refTuplesIncludingContentIds, allContents)
    }

    fun createGraphDataForContent(content: Content, allContents: List<Content>): GraphData {
        val contentRefDataList: List<ContentRefData> =
            allContents
                .mapNotNull {
                    it.refs?.map { ref -> ContentRefData(it.contentId, ref, "dummy") }
                }
                .flatten()
        var nextSearchableContents = ArrayList<ContentID>()
        val alreadySearchedContents = ArrayList<ContentID>()
        val finalRefList = ArrayList<ContentRefData>()
        nextSearchableContents.add(content.contentId)
        var lengthOfOldList: Int
        var lengthOfNewList: Int
        do {
            lengthOfOldList = nextSearchableContents.count()
            val contentsToAddToNextSearchableContentsList = ArrayList<ContentID>()
            nextSearchableContents.forEach {
                if (!alreadySearchedContents.contains(it)) {
                    contentRefDataList.forEach { ref ->
                        if (ref.first == it) {
                            if (!finalRefList.contains(ref)) {
                                finalRefList.add(ref)
                            }
                            contentsToAddToNextSearchableContentsList.add(ref.second)
                        } else if (ref.second == it) {
                            if (!finalRefList.contains(ref)) {
                                finalRefList.add(ref)
                            }
                            contentsToAddToNextSearchableContentsList.add(ref.first)
                        }
                    }
                    alreadySearchedContents.add(it)
                }
            }
            nextSearchableContents.addAll(contentsToAddToNextSearchableContentsList)
            nextSearchableContents = ArrayList(nextSearchableContents.distinct())
            lengthOfNewList = nextSearchableContents.count()
        } while (lengthOfNewList > lengthOfOldList)
        return getGraphDataResponseViaContentRefDataList(finalRefList, allContents)
    }

    fun updateGraphDataOfAllContents() {
        dataHolder.data = dataHolder.data!!.copy(
            wholeGraphData = createWholeGraphData(dataHolder.data!!.contents),
            graphDataOfContents = dataHolder.data!!.contents.map {
                it.contentId to createGraphDataForContent(it, dataHolder.data!!.contents)
            }.toMap()
        )
    }

    fun getGraphDataForContent(content: Content): GraphData = dataHolder.data!!.graphDataOfContents[content.contentId]!!

    private fun getGraphDataResponseViaContentRefDataList(
        contentRefDataList: List<ContentRefData>,
        allContents: List<Content>
    ): GraphData {
        val temp = ArrayList<Content>()
        contentRefDataList.forEach { refData ->
            val fromContent: Content = allContents.find { it.contentId == refData.first }!!
            temp.add(fromContent)
            val toContent: Content = allContents.find { it.contentId == refData.second }!!
            temp.add(toContent)
        }
        val uniqueContentsWhichArePartOfAtLeastOneReference = temp.distinctBy { it.contentId }
        val uniqueTitlesOfContentsWhichArePartsOfAtLeastOneReference: List<String> =
            uniqueContentsWhichArePartOfAtLeastOneReference.map {
                it.title ?: createBeautifiedContentText(it, "contentGraphNodeHoverText")
            }
        val uniqueIdsOfContentsWhichArePartOfAtLeastOneReference =
            uniqueContentsWhichArePartOfAtLeastOneReference.map { it.contentId }
        val refTuplesIncludingIndexes =
            contentRefDataList.map { (fromContentId, toContentId) ->
                val fromIndex = uniqueIdsOfContentsWhichArePartOfAtLeastOneReference.indexOf(fromContentId)
                val toIndex = uniqueIdsOfContentsWhichArePartOfAtLeastOneReference.indexOf(toContentId)
                Tuple2(fromIndex, toIndex)
            }
        return GraphData(
            uniqueTitlesOfContentsWhichArePartsOfAtLeastOneReference,
            uniqueIdsOfContentsWhichArePartOfAtLeastOneReference,
            refTuplesIncludingIndexes
        )
    }

    fun createBeautifiedContentText(content: Content, forWhat: String): String {
        val letterCountToShow = when (forWhat) {
            "contentPageTitle" -> 60
            "contentGraphNodeHoverText" -> 100
            "relatedContentLinkHover" -> 100
            else -> 100
        }
        val contentFullText = content.content!!

        var restOfContent = contentFullText
        var uniqueContent = ""
        while (restOfContent.contains("(http") && contentFullText.contains("[")) {
            uniqueContent += restOfContent.split('[')[0]

            uniqueContent += restOfContent.split('[')[1]
                .split(']')[0]

            val indexOfFirst = restOfContent.indexOfFirst { it == ')' }

            restOfContent = restOfContent.substring(indexOfFirst + 1)
        }

        uniqueContent += restOfContent

        return uniqueContent.take(letterCountToShow)
            .trim() + if (uniqueContent.length > letterCountToShow) "..." else ""
    }

    fun getContentsResponseByKeywordSearch(
        req: SearchContentRequest
    ): SearchContentResponse {
        val contents: List<ContentResponse> =
            repository.getEntities()
                .filter {
                    StringUtils.containsIgnoreCase(it.content!!, req.keyword)
                            || StringUtils.containsIgnoreCase(it.title, req.keyword)
                            || (it.textToSearchOn != null && StringUtils.containsIgnoreCase(
                        it.textToSearchOn,
                        req.keyword
                    ))
                }
                .filter { it.tags.count() > 0 } // hidden contents have no tags and we don't want to show them on search result
                .map { ContentResponse.createWith(it, repository, this) }
                .sortedBy { it.dateAsTimestamp }
                .reversed()
        return SearchContentResponse(contents)
    }

    fun getFurtherReadingRefs(content: Content): List<Ref> {
        val allContents = repository.getEntities()
        val contentRefDataList: List<ContentRefData> =
            allContents
                .mapNotNull {
                    it.refs?.map { ref -> ContentRefData(it.contentId, ref, "dummy") }
                }
                .flatten()
        val furtherReadingList = ArrayList<ContentID>()
        contentRefDataList.forEach { ref ->
            if (ref.second == content.contentId) {
                if (!furtherReadingList.contains(ref)) {
                    furtherReadingList.add(ref.first)
                }
            }
        }
        return furtherReadingList
            .mapNotNull { id -> repository.findEntity(id.toString()) }
            .map(Ref.Companion::createWith)
            .distinctBy { it.id }
    }
}
package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.entity.*
import com.philocoder.tagging_system.model.request.ContentsOfTagRequest
import com.philocoder.tagging_system.model.request.SearchContentRequest
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.ContentsResponse
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository
import org.apache.commons.lang3.StringUtils
import org.springframework.stereotype.Service

@Service
class ContentService(
    private val repository: ContentRepository,
    private val tagRepository: TagRepository
) {

    fun getContentsResponse(req: ContentsOfTagRequest): ContentsResponse {
        val tagIdToUse = if (req.tagId == "tagging-system-home-page") tagRepository.getHomeTag() else req.tagId
        val tag: Tag = tagRepository.findEntity(tagIdToUse)
            ?: return ContentsResponse.empty
        val contentResponses = repository
            .getContentsForTag(tag)
            .map { ContentResponse.createWith(it) }
        val contentCount =
            repository.getContentCount(tag.name)
        return ContentsResponse(contentResponses)
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
                .map { ContentResponse.createWith(it) }
                .sortedBy { it.dateAsTimestamp }
                .reversed()
        return SearchContentResponse(contents)
    }
}
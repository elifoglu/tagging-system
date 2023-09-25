package com.philocoder.tagging_system.model.response

import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.GraphData
import com.philocoder.tagging_system.model.entity.Ref
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.service.ContentService
import java.util.*

data class ContentResponse(
    val title: String?,
    val dateAsTimestamp: String,
    val contentId: ContentID,
    val content: String?,
    val tags: List<String>,
    val refs: List<Ref>,
    val graphData: GraphData,
    val furtherReadingRefs: List<Ref>
) {

    companion object {
        fun createWith(content: Content, repo: ContentRepository, service: ContentService?): ContentResponse {
            val refs: List<Ref> = content.refs
                ?.mapNotNull { id -> repo.findEntity(id.toString()) }
                ?.map(Ref.Companion::createWith)
                ?.distinctBy { it.id }
                ?: Collections.emptyList()
            return ContentResponse(
                title = content.title,
                dateAsTimestamp = content.dateAsTimestamp.toString(),
                contentId = content.contentId,
                content = content.content,
                tags = content.tags,
                refs = refs,
                graphData = service?.getGraphDataForContent(content) ?: GraphData.empty,
                furtherReadingRefs = service?.getFurtherReadingRefs(content) ?: Collections.emptyList()
            )
        }

    }
}
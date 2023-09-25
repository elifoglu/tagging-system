package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.GraphData
import com.philocoder.tagging_system.model.request.*
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.ContentsResponse
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository
import com.philocoder.tagging_system.service.ContentService
import org.springframework.web.bind.annotation.*
import java.util.*


@RestController
class ContentController(
    private val contentRepository: ContentRepository,
    private val tagRepository: TagRepository,
    private val service: ContentService,
    private val dataHolder: DataHolder
) {

    @CrossOrigin
    @PostMapping("/contents-of-tag")
    fun get(@RequestBody req: ContentsOfTagRequest): ContentsResponse {
        return service.getContentsResponse(req)
    }

    @CrossOrigin
    @GetMapping("/graph-data")
    fun getAllGraphData(): GraphData =
        dataHolder.data!!.wholeGraphData

    @CrossOrigin
    @PostMapping("/get-content")
    fun getContent(@RequestBody req: GetContentRequest): ContentResponse {
        return ContentResponse.createWith(
            contentRepository.findEntity(req.contentID)!!,
            contentRepository,
            service
        )
    }

    @CrossOrigin
    @PostMapping("/contents")
    fun addContent(@RequestBody req: CreateContentRequest): ContentResponse =
        Content.createIfValidForCreation(req, contentRepository, tagRepository)!!
            .apply {
                contentRepository.addEntity(contentId.toString(), this)
                Thread.sleep(1000)
                service.updateGraphDataOfAllContents()
            }
            .let { ContentResponse.createWith(it, contentRepository, null) }

    @CrossOrigin
    @PostMapping("/contents/{contentId}")
    fun updateContent(
        @PathVariable("contentId") contentId: String,
        @RequestBody req: UpdateContentRequest
    ): ContentResponse =
        Content.createIfValidForUpdate(contentId.toInt(), req, contentRepository, tagRepository)!!
            .apply {
                contentRepository.deleteEntity(contentId)
                Thread.sleep(1000)
                contentRepository.addEntity(contentId, this)
                Thread.sleep(1000)
                service.updateGraphDataOfAllContents()
            }
            .let { ContentResponse.createWith(it, contentRepository, null) }

    @CrossOrigin
    @PostMapping("/preview-content")
    fun previewContent(@RequestBody req: CreateContentRequest): ContentResponse =
        Content.createIfValidForPreview(req.id.toInt(), req, contentRepository, tagRepository)!!
            .let { ContentResponse.createWith(it, contentRepository, null) }

    @CrossOrigin
    @PostMapping("/search")
    fun searchContent(@RequestBody req: SearchContentRequest): SearchContentResponse {
        return service.getContentsResponseByKeywordSearch(req)
    }
}
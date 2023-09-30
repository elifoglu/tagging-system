package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.request.*
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.model.response.TagTextResponse
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.service.ContentService
import org.springframework.web.bind.annotation.*


@RestController
class ContentController(
    private val contentRepository: ContentRepository,
    private val service: ContentService,
) {

    @CrossOrigin
    @PostMapping("/contents-of-tag")
    fun get(@RequestBody req: ContentsOfTagRequest): TagTextResponse {
        return service.getContentsResponse(req)
    }


    @CrossOrigin
    @PostMapping("/get-content")
    fun getContent(@RequestBody req: GetContentRequest): ContentResponse {
        return ContentResponse.createWith(
            contentRepository.findEntity(req.contentID)!!
        )
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/contents")
    fun createContent(@RequestBody req: CreateContentRequest): String =
        Content.createIfValidForCreation(req, contentRepository)!!
            .run {
                contentRepository.addEntity( this)
                //dataService.regenerateWholeData() for now, i do not know if i gonna need this
                "done"
            }


    @CrossOrigin
    @PostMapping("/contents/{contentId}")
    fun updateContent(
        @PathVariable("contentId") contentId: String,
        @RequestBody req: UpdateContentRequest
    ): String =
        Content.createIfValidForUpdate(contentId, req, contentRepository)!!
            .run {
                contentRepository.updateEntity(this)
                //dataService.regenerateWholeData() for now, i do not know if i gonna need this
                "done"
            }

    @CrossOrigin
    @PostMapping("/search")
    fun searchContent(@RequestBody req: SearchContentRequest): SearchContentResponse {
        return service.getContentsResponseByKeywordSearch(req)
    }
}
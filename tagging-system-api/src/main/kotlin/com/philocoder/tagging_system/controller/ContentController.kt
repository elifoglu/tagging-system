package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.request.*
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.model.response.TagTextResponse
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.service.ContentService
import com.philocoder.tagging_system.service.drag.DragService
import com.philocoder.tagging_system.util.DateUtils.now
import org.springframework.web.bind.annotation.*


@RestController
class ContentController(
    private val contentService: ContentService,
    private val dragService: DragService,
    private val dataHolder: DataHolder
) {

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/contents-of-tag")
    fun get(@RequestBody req: ContentsOfTagRequest): TagTextResponse {
        return contentService.getContentsResponse(req)
    }


    @CrossOrigin
    @PostMapping("/get-content")
    fun getContent(@RequestBody req: GetContentRequest): ContentResponse {
        return ContentResponse.createWith(
            contentService.findEntity(req.contentID)!!
        )
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/contents")
    fun createContent(@RequestBody req: CreateContentRequest): String =
        Content.createIfValidForCreation(req, contentService)!!
            .run {
                dataHolder.addContent(this, now())
                //dataService.regenerateWholeData() for now, i do not know if i gonna need this
                "done"
            }


    @CrossOrigin
    @PostMapping("/contents/{contentId}")
    fun updateContent(
        @PathVariable("contentId") contentId: String,
        @RequestBody req: UpdateContentRequest
    ): String =
        Content.createIfValidForUpdate(contentId, req, contentService)!!
            .run {
                dataHolder.updateContent(this, now())
                //dataService.regenerateWholeData() for now, i do not know if i gonna need this
                "done"
            }

    @CrossOrigin
    @PostMapping("/delete-content/{contentId}")
    fun deleteContent(
        @PathVariable("contentId") contentId: String,
    ): String =
        Content.returnItsIdIfValidForDelete(contentId, contentService)
            .fold({ err -> err }, { id -> dataHolder.deleteContent(id, now()).run { "done" } })

    @CrossOrigin
    @PostMapping("/search")
    fun searchContent(@RequestBody req: SearchContentRequest): SearchContentResponse {
        return contentService.getContentsResponseByKeywordSearch(req)
    }

    @CrossOrigin
    @PostMapping("/drag-content")
    fun dragContent(@RequestBody req: DragContentRequest): String {
        return dragService.dragContent(req, now())
    }
}
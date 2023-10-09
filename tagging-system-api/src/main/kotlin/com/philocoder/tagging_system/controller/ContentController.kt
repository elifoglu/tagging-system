package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.request.*
import com.philocoder.tagging_system.model.response.ContentPageResponse
import com.philocoder.tagging_system.model.response.ContentResponse
import com.philocoder.tagging_system.model.response.SearchContentResponse
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.service.ContentService
import com.philocoder.tagging_system.service.ContentViewOrderService
import com.philocoder.tagging_system.service.DataService
import com.philocoder.tagging_system.service.drag.DragService
import com.philocoder.tagging_system.util.DateUtils.now
import org.springframework.web.bind.annotation.*


@RestController
class ContentController(
    private val contentService: ContentService,
    private val contentViewOrderService: ContentViewOrderService,
    private val dragService: DragService,
    private val dataHolder: DataHolder,
    private val dataService: DataService
) {

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/get-content")
    fun getContentForContentPage(@RequestBody req: GetContentRequest): ContentPageResponse? {
        val maybeContent = contentService.findExistingEntity(req.contentId) ?: return null
        return ContentPageResponse(ContentResponse.createWith(maybeContent, null))
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/contents")
    fun createContent(@RequestBody req: CreateContentRequest): String =
        Content.createIfValidForCreation(req, contentService)!!
            .run {
                val now = now()
                dataHolder.addContent(this, now)
                if (req.existingContentContentIdToAddFrontOrBackOfIt == null
                    || req.existingContentTagIdToAddFrontOrBackOfIt == null
                    || req.frontOrBack == null
                ) {
                    contentViewOrderService.updateContentViewOrderForCreatedContent(this, now)
                } else {
                    contentViewOrderService.updateContentViewOrderForCreatedContentViaCSABox(
                        this,
                        req.existingContentContentIdToAddFrontOrBackOfIt,
                        req.existingContentTagIdToAddFrontOrBackOfIt,
                        req.frontOrBack,
                        now
                    )
                }

                //dataService.regenerateWholeData() for now, i do not know if i gonna need this

                dataService.writeAllDataToDataFile()
                "done"
            }


    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/contents/{contentId}")
    fun updateContent(
        @PathVariable("contentId") contentId: String,
        @RequestBody req: UpdateContentRequest
    ): String {
        val content = Content.createIfValidForUpdate(contentId, req, contentService)!!
        val previousVersionOfContent = contentService.findEntity(contentId)!!
        if (
            content.title == previousVersionOfContent.title
            && content.content == previousVersionOfContent.content
            && content.tags == previousVersionOfContent.tags
        ) {
            return "done"
        }
        val now = now()
        dataHolder.updateContent(content, now)
        contentViewOrderService.updateContentViewOrderForUpdatedContent(previousVersionOfContent, content, now)
        //dataService.regenerateWholeData() for now, i do not know if i gonna need this

        dataService.writeAllDataToDataFile()
        return "done"
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/delete-content/{contentId}")
    fun deleteContent(
        @PathVariable("contentId") contentId: String,
    ): String =
        Content.returnItsIdIfValidForDelete(contentId, contentService)
            .fold({ err -> err }, { content ->
                val now = now()
                dataHolder.deleteContent(content.contentId, now)
                contentViewOrderService.updateContentViewOrderForDeletedContent(content, now)

                dataService.writeAllDataToDataFile()
                 "done"
            }
            )

    @CrossOrigin
    @PostMapping("/search")
    fun searchContent(@RequestBody req: SearchContentRequest): SearchContentResponse {
        return contentService.getContentsResponseByKeywordSearch(req)
    }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/drag-content")
    fun dragContent(@RequestBody req: DragContentRequest): String {
        val result = dragService.dragContent(req, now())

        dataService.writeAllDataToDataFile()
        return result;
    }
}
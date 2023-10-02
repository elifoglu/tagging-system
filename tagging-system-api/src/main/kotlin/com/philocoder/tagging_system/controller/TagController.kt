package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.CreateTagRequest
import com.philocoder.tagging_system.model.request.DeleteTagRequest
import com.philocoder.tagging_system.model.request.UpdateTagRequest
import com.philocoder.tagging_system.model.response.InitialDataResponse
import com.philocoder.tagging_system.model.response.TagResponse
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.service.*
import com.philocoder.tagging_system.util.DateUtils.now
import org.springframework.web.bind.annotation.*


@RestController
class TagController(
    private val tagService: TagService,
    private val contentService: ContentService,
    private val contentViewOrderService: ContentViewOrderService,
    private val dataService: DataService,
    private val tagDeletionService: TagDeletionService,
    private val dataHolder: DataHolder
) {

    @CrossOrigin
    @GetMapping("/get-initial-data")
    fun getInitialData(): InitialDataResponse {
        val allTags: List<Tag> = tagService.getNotDeletedAllTags()
        return InitialDataResponse(
            allTags = allTags.map {
                TagResponse.create(
                    it,
                    tagService,
                    contentService
                )
            },
            homeTagId = tagService.getHomeTag(),
            undoable = !dataHolder.isRollbackStackEmpty()
        )
    }

    @CrossOrigin
    @PostMapping("/tags")
    @kotlin.ExperimentalStdlibApi
    fun createTag(@RequestBody req: CreateTagRequest): String =
        Tag.createIfValidForCreation(req, tagService)!!
            .run {
                dataHolder.addTag(this, now())
                dataService.regenerateWholeData()
                "done"
            }

    @CrossOrigin
    @PostMapping("/tags/{tagId}")
    @kotlin.ExperimentalStdlibApi
    fun updateTag(
        @PathVariable("tagId") tagId: String,
        @RequestBody req: UpdateTagRequest
    ): String =
        Tag.createIfValidForUpdate(tagId, req, tagService)!!
            .run {
                dataHolder.updateTag(this, now())
                dataService.regenerateWholeData()
                "done"
            }

    @ExperimentalStdlibApi
    @CrossOrigin
    @PostMapping("/delete-tag/{tagId}")
    fun deleteTag(
        @PathVariable("tagId") tagId: String,
        @RequestBody req: DeleteTagRequest
    ): String =
        Tag.returnItsIdIfValidForDelete(tagId, req, tagService, dataService)
            .fold({ err -> err }, { tag ->
                val now = now()
                tagDeletionService.deleteTagWithStrategy(tag.tagId, req.tagDeletionStrategy, now)
                dataService.regenerateWholeData()
                "done"
            })
}
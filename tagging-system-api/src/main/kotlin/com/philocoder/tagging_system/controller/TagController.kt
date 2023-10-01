package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.CreateTagRequest
import com.philocoder.tagging_system.model.request.DeleteTagRequest
import com.philocoder.tagging_system.model.request.UpdateTagRequest
import com.philocoder.tagging_system.model.response.InitialDataResponse
import com.philocoder.tagging_system.model.response.TagResponse
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.repository.TagRepository
import com.philocoder.tagging_system.service.DataService
import com.philocoder.tagging_system.service.TagDeletionService
import org.springframework.web.bind.annotation.*


@RestController
class TagController(
    private val tagRepository: TagRepository,
    private val contentRepository: ContentRepository,
    private val dataService: DataService,
    private val tagDeletionService: TagDeletionService,
    private val dataHolder: DataHolder
) {

    @CrossOrigin
    @GetMapping("/get-initial-data")
    fun getInitialData(): InitialDataResponse {
        val allTags: List<Tag> = tagRepository.getNotDeletedAllTags()
        return InitialDataResponse(
            allTags = allTags.map {
                TagResponse.create(
                    it,
                    tagRepository,
                    contentRepository
                )
            },
            homeTagId = tagRepository.getHomeTag()
        )
    }

    @CrossOrigin
    @PostMapping("/tags")
    @kotlin.ExperimentalStdlibApi
    fun createTag(@RequestBody req: CreateTagRequest): String =
        Tag.createIfValidForCreation(req, tagRepository)!!
            .run {
                dataHolder.addTag(this)
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
        Tag.createIfValidForUpdate(tagId, req, tagRepository)!!
            .run {
                dataHolder.updateTag(this)
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
        Tag.returnItsIdIfValidForDelete(tagId, req, tagRepository, dataService)
            .fold({ err -> err }, { id ->
                tagDeletionService.deleteTagWithStrategy(id, req.tagDeletionStrategy)
                dataService.regenerateWholeData()
                "done"
            })
}
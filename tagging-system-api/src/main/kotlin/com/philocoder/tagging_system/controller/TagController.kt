package com.philocoder.tagging_system.controller

import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.model.request.CreateTagRequest
import com.philocoder.tagging_system.model.request.UpdateTagRequest
import com.philocoder.tagging_system.model.response.AllTagsResponse
import com.philocoder.tagging_system.model.response.TagResponse
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.TagRepository
import org.springframework.web.bind.annotation.*


@RestController
class TagController(
    private val tagRepository: TagRepository,
    private val contentRepository: ContentRepository
) {

    @CrossOrigin
    @GetMapping("/get-all-tags")
    fun getAllTags(): AllTagsResponse {
        val allTags: List<Tag> = tagRepository.getAllTags()
        return AllTagsResponse(
            allTags = allTags.map {
                TagResponse.createForAllContentsMode(
                    it,
                    contentRepository
                )
            }
                .filter { it.contentCount != 0 }
        )
    }

    @CrossOrigin
    @PostMapping("/tags")
    fun addTag(@RequestBody req: CreateTagRequest): String =
        Tag.createIfValidForCreation(req, tagRepository)!!
            .run {
                tagRepository.addEntity(tagId, this)
                "done"
            }

    @CrossOrigin
    @PostMapping("/tags/{tagId}")
    fun updateTag(
        @PathVariable("tagId") tagId: String,
        @RequestBody req: UpdateTagRequest
    ): String =
        Tag.createIfValidForUpdate(tagId, req, tagRepository)!!
            .run {
                tagRepository.deleteEntity(tagId)
                Thread.sleep(1000)
                tagRepository.addEntity(tagId, this)
                "done"
            }

    @GetMapping("/delete-all-tags")
    fun deleteAllTags(): Unit =
        tagRepository.deleteAll()
}
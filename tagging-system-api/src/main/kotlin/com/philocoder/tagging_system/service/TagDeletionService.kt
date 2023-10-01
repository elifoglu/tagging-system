package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.request.GenerateDataRequest
import com.philocoder.tagging_system.repository.TagRepository
import org.springframework.stereotype.Service
import java.util.*

@Service
class TagDeletionService(
    private val tagRepository: TagRepository,
    private val dataService: DataService
) {
    companion object {
        @ExperimentalStdlibApi
        val deleteOnlyTagFn: (String, TagRepository, DataService) -> Unit = { tagId: String, tagRepo: TagRepository, dataService: DataService ->
            tagRepo.deleteEntity(tagId)
            dataService.regenerateWholeData()
            "done"
        }

        @ExperimentalStdlibApi
        val deleteTagAndChildContentsFn: (String, TagRepository, DataService) -> Unit = { tagId: String, tagRepo: TagRepository, dataService: DataService ->
            //TODO
            dataService.regenerateWholeData()
            "done"
        }

        @ExperimentalStdlibApi
        val deleteTagWithAllDescendants: (String, TagRepository, DataService) -> Unit = { tagId: String, tagRepo: TagRepository, dataService: DataService ->
            //TODO
            dataService.regenerateWholeData()
            "done"
        }

        @ExperimentalStdlibApi
        val tagDeletionStrategies: HashMap<String, (tagId: String, tagRepo: TagRepository, dataService: DataService) -> Unit> =
            hashMapOf(
                "only-tag" to deleteOnlyTagFn,
                "tag-and-child-contents" to deleteTagAndChildContentsFn,
                "tag-with-all-descendants" to deleteTagWithAllDescendants
            )

        @ExperimentalStdlibApi
        fun isValidStrategy(str: String)
         = tagDeletionStrategies.keys.contains(str)

        @ExperimentalStdlibApi
        fun getStrategyFn(str: String): ((tagId: String, tagRepo: TagRepository, dataService: DataService) -> Unit)
                = tagDeletionStrategies[str]!!

    }

    @ExperimentalStdlibApi
    fun deleteTagWithStrategy(tagId: String, tagDeletionStrategy: String): String {
        if(!isValidStrategy(tagDeletionStrategy)) {
            "not-valid-strategy"
        }
        getStrategyFn(tagDeletionStrategy).invoke(tagId, )

        return setWholeData(GenerateDataRequest(req.contents, req.tags, req.homeTagId))
    }
}
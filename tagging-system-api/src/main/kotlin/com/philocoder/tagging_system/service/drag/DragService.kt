package com.philocoder.tagging_system.service.drag

import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository
import org.springframework.stereotype.Service

@Service
open class DragService(
    private val lineViewDragService: LineViewDragService,
    private val groupViewDragService: GroupViewDragService,
    private val distinctGroupViewDragService: DistinctGroupViewDragService
) {

    @ExperimentalStdlibApi
    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
        if (!arrayListOf("front", "back").contains(req.dropToFrontOrBack)) {
            return "not-existing-path"
        }

        return when (req.tagTextViewType) {
            "line" -> {
                lineViewDragService.dragContent(req, rollbackMoment)
            }
            "group" -> {
                groupViewDragService.dragContent(req, rollbackMoment)
            }
            "distinct-group" -> {
                distinctGroupViewDragService.dragContent(req, rollbackMoment)
            }
            else -> "not-ok"
        }
    }
}



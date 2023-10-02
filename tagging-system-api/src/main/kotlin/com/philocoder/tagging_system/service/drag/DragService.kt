package com.philocoder.tagging_system.service.drag

import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository

@Repository
open class DragService(
    private val lineViewDragService: LineViewDragService,
    private val groupViewDragService: DistinctGroupViewDragService,
    private val distinctGroupViewDragService: DistinctGroupViewDragService,
    private val dataHolder: DataHolder
) {

    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
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



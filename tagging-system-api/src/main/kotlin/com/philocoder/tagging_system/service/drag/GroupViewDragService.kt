package com.philocoder.tagging_system.service.drag

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository

@Repository
open class GroupViewDragService(
    private val dataHolder: DataHolder
) {

    /* I WROTE THIS AT THE START OF LineViewDragService.tryToDragContentToAnotherTextPart but I noticed that LineView does not need this,
       BUT GROUP VIEW GONNA NEED, SO KEEP IT FOR NOW
            val foundTagTextPartOfContentToDropOn =
            tagTextPartsForDistinctGroupView.find { it.tag.tagId == droppedOnContentTagIdDuo.b }!!
        if (foundTagTextPartOfContentToDropOn.contents.filter { it.contentId == draggedContentTagIdDuo.a }
                .isNotEmpty()) {
            return "cannot-drag-to-a-text-part-if-it-already-contains-content"
        }
    * */
    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
        return "ok"
    }
}



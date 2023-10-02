package com.philocoder.tagging_system.service.drag

import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository

@Repository
open class DistinctGroupViewDragService(
    private val dataHolder: DataHolder
) {

    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
        val currentOrder = dataHolder.getAllData().contentViewOrder

        val contentTagDuoToDrag =
            currentOrder.find { (a, b) -> a == req.idOfDraggedContent && b == req.idOfTagGroupThatDraggedContentBelong }!!

        val orderAfterDuoRemoved = currentOrder.filterNot { it == contentTagDuoToDrag }

        val contentTagDuoToDropDraggedOn =
            orderAfterDuoRemoved.find { (a, b) -> a == req.idOfContentToDropOn && b == req.idOfTagGroupToDropOn }!!

        val index = orderAfterDuoRemoved
            .indexOf(contentTagDuoToDropDraggedOn)

        val leftSideOfTheList = orderAfterDuoRemoved.take(index)
        val rightSideOfTheList = orderAfterDuoRemoved.drop(index + 1)

        return "ok"
    }


}



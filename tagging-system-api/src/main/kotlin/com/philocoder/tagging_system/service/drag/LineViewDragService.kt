package com.philocoder.tagging_system.service.drag

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository

@Repository
open class LineViewDragService(
    private val dataHolder: DataHolder
) {

    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
        if (!arrayListOf("front", "back").contains(req.dropToFrontOrBack)) {
            return "not-existing-path"
        }

        val currentOrder = dataHolder.getAllData().contentViewOrder
        val currentOrderOnLineView: ArrayList<ContentID> = arrayListOf()
        currentOrder.forEach {
            if (!currentOrderOnLineView.contains(it.a)) {
                currentOrderOnLineView.add(it.a)
            }
        }

        val draggedToUpside: Boolean =
            draggedToUpside(currentOrderOnLineView, req.idOfDraggedContent, req.idOfContentToDropOn)

        if (onAfterAnotherAndNotMoveable(
                currentOrderOnLineView,
                req.idOfDraggedContent,
                req.idOfContentToDropOn,
                req.dropToFrontOrBack
            )
        ) {
            return "it-will-stay-on-same-place-so-no-need-to-drag"
        }

        val contentTagDuoToDrag: Tuple2<ContentID, TagID> =
            currentOrder.find { (a, _) -> a == req.idOfDraggedContent }!!

        val orderAfterDuoRemoved = currentOrder.filterNot { it == contentTagDuoToDrag }

        val contentTagDuoToDropDraggedOn: Tuple2<ContentID, TagID> =
            if (draggedToUpside) {
                orderAfterDuoRemoved.find { (a, _) -> a == req.idOfContentToDropOn }!!
            } else {
                orderAfterDuoRemoved.findLast { (a, _) -> a == req.idOfContentToDropOn }!!
            }

        val index = orderAfterDuoRemoved
            .indexOf(contentTagDuoToDropDraggedOn)

        val leftSideOfTheList = orderAfterDuoRemoved.take(index)
        val rightSideOfTheList = orderAfterDuoRemoved.drop(index + 1)
        val newContentViewOrder: ArrayList<Tuple2<ContentID, TagID>> =
            ArrayList()
        newContentViewOrder.addAll(leftSideOfTheList)

        if (req.dropToFrontOrBack == "front") {
            newContentViewOrder.add(contentTagDuoToDrag)
            newContentViewOrder.add(contentTagDuoToDropDraggedOn)
        } else {
            newContentViewOrder.add(contentTagDuoToDropDraggedOn)
            newContentViewOrder.add(contentTagDuoToDrag)
        }

        newContentViewOrder.addAll(rightSideOfTheList)

        dataHolder.updateContentViewOrderWith(newContentViewOrder, rollbackMoment)

        return "ok"
    }

    private fun draggedToUpside(
        currentOrderOnLineView: List<String>,
        draggedContentId: String,
        droppedOnContentId: String
    ): Boolean {
        return currentOrderOnLineView.indexOf(draggedContentId) > currentOrderOnLineView.indexOf(droppedOnContentId)
    }

    private fun onAfterAnotherAndNotMoveable(
        currentOrderOnLineView: List<String>,
        draggedContentId: String,
        droppedOnContentId: String,
        droppedToFrontOrBack: String
    ): Boolean {
        return (currentOrderOnLineView.indexOf(draggedContentId) - currentOrderOnLineView.indexOf(droppedOnContentId) == 1 && droppedToFrontOrBack == "back") ||
                (currentOrderOnLineView.indexOf(droppedOnContentId) - currentOrderOnLineView.indexOf(draggedContentId) == 1 && droppedToFrontOrBack == "front")
    }
}



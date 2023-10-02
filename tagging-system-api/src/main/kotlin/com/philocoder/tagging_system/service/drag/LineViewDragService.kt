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

        val contentTagDuosToDrag: List<Tuple2<ContentID, TagID>> =
            currentOrder.filter { (a, _) -> a == req.idOfDraggedContent }!!

        val orderStatusAfterDuosToDragAreRemoved = currentOrder.filterNot { contentTagDuosToDrag.contains(it) }

        val contentTagDuoToDropDraggedOn: Tuple2<ContentID, TagID> =
            if (draggedToUpside) {
                orderStatusAfterDuosToDragAreRemoved.find { (a, _) -> a == req.idOfContentToDropOn }!!
            } else {
                orderStatusAfterDuosToDragAreRemoved.findLast { (a, _) -> a == req.idOfContentToDropOn }!!
            }

        val index = orderStatusAfterDuosToDragAreRemoved
            .indexOf(contentTagDuoToDropDraggedOn)

        val leftSideOfTheList = orderStatusAfterDuosToDragAreRemoved.take(index)
        val rightSideOfTheList = orderStatusAfterDuosToDragAreRemoved.drop(index + 1)
        val newContentViewOrder: ArrayList<Tuple2<ContentID, TagID>> = ArrayList()
        newContentViewOrder.addAll(leftSideOfTheList)

        if (req.dropToFrontOrBack == "front") {
            contentTagDuosToDrag.forEach { newContentViewOrder.add(it) }
            newContentViewOrder.add(contentTagDuoToDropDraggedOn)
        } else {
            newContentViewOrder.add(contentTagDuoToDropDraggedOn)
            contentTagDuosToDrag.forEach { newContentViewOrder.add(it) }
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



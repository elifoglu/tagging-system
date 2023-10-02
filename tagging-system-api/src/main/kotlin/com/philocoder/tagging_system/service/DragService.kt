package com.philocoder.tagging_system.service

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository

@Repository
open class DragService(
    private val tagService: TagService,
    private val dataHolder: DataHolder
) {

    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
        return when (req.tagTextViewType) {
            "line" -> {
                dragContentOnLineView(req, rollbackMoment)
            }
            "group" -> {
                dragContentOnGroupView(req, rollbackMoment)
            }
            "distinct-group" -> {
                dragContentOnDistinctGroupView(req, rollbackMoment)
            }
            else -> "not-ok"
        }
    }

    fun dragContentOnLineView(req: DragContentRequest, rollbackMoment: Long): String {
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

        val contentTagDuoToDrag: Tuple2<ContentID, TagID> =
            currentOrder.find { (a, _) -> a == req.idOfDraggedContent }!!

        val orderAfterDuoRemoved = currentOrder.filterNot { it == contentTagDuoToDrag }

        val contentTagDuoToDropDraggedOn: Tuple2<ContentID, TagID> =
            orderAfterDuoRemoved.find { (a, _) -> a == req.idOfContentToDropOn }!!

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

    fun dragContentOnGroupView(req: DragContentRequest, rollbackMoment: Long): String {
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

    fun dragContentOnDistinctGroupView(req: DragContentRequest, rollbackMoment: Long): String {
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



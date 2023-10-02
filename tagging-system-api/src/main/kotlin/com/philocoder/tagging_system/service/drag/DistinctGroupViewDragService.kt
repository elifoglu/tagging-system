package com.philocoder.tagging_system.service.drag

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.model.response.TagTextResponse
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.service.ContentService
import com.philocoder.tagging_system.service.TagService
import com.philocoder.tagging_system.util.DateUtils.now
import org.springframework.stereotype.Service

@Service
open class DistinctGroupViewDragService(
    private val contentService: ContentService,
    private val tagService: TagService,
    private val dataHolder: DataHolder
) {

    @ExperimentalStdlibApi
    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
        val currentOrder = dataHolder.getAllData().contentViewOrder
        val tagTextPartsForDistinctGroupView: List<TagTextResponse.TagTextPart> =
            contentService.getTagTextPartsForDistinctGroupView(tagService.findEntity(req.idOfActiveTagPage)!!)
        tagTextPartsForDistinctGroupView

        val currentOrderOnDistinctGroupView: ArrayList<Tuple2<ContentID, TagID>> = arrayListOf()

        tagTextPartsForDistinctGroupView.forEach { tagTextPart ->
            tagTextPart.contents.forEach {
                currentOrderOnDistinctGroupView.add(Tuple2(it.contentId, tagTextPart.tag.tagId))
            }
        }

        val draggedContentIdTagIdDuo = Tuple2(req.idOfDraggedContent, req.idOfTagGroupThatDraggedContentBelong)
        val toDropOnContentIdTagIdDuo = Tuple2(req.idOfContentToDropOn, req.idOfTagGroupToDropOn)

        if (isADragAttemptContentToAnotherTagTextPart(draggedContentIdTagIdDuo, toDropOnContentIdTagIdDuo)) {
            return tryToDragContentToAnotherTextPart(
                req,
                currentOrder,
                currentOrderOnDistinctGroupView,
                draggedContentIdTagIdDuo,
                toDropOnContentIdTagIdDuo,
                rollbackMoment
            )
        }

        val draggedToUpside: Boolean =
            draggedToUpside(currentOrderOnDistinctGroupView, draggedContentIdTagIdDuo, toDropOnContentIdTagIdDuo)

        if (oneAfterAnotherAndNotMoveable(
                currentOrderOnDistinctGroupView,
                draggedContentIdTagIdDuo,
                toDropOnContentIdTagIdDuo,
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
        currentOrderOnDistinctGroupView: List<Tuple2<ContentID, TagID>>,
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>
    ): Boolean {
        return currentOrderOnDistinctGroupView.indexOf(draggedContentTagIdDuo) > currentOrderOnDistinctGroupView.indexOf(
            droppedOnContentTagIdDuo
        )
    }

    private fun oneAfterAnotherAndNotMoveable(
        currentOrderOnDistinctGroupView: List<Tuple2<ContentID, TagID>>,
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedToFrontOrBack: String
    ): Boolean {
        if (theyDoNotBelongToSameTagTextPart(draggedContentTagIdDuo, droppedOnContentTagIdDuo)) {
            return false
        }

        return (currentOrderOnDistinctGroupView.indexOf(draggedContentTagIdDuo) - currentOrderOnDistinctGroupView.indexOf(
            droppedOnContentTagIdDuo
        ) == 1 && droppedToFrontOrBack == "back") ||
                (currentOrderOnDistinctGroupView.indexOf(droppedOnContentTagIdDuo) - currentOrderOnDistinctGroupView.indexOf(
                    draggedContentTagIdDuo
                ) == 1 && droppedToFrontOrBack == "front")
    }

    private fun theyDoNotBelongToSameTagTextPart(
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>
    ): Boolean {
        return draggedContentTagIdDuo.b != droppedOnContentTagIdDuo.b
    }

    private fun isADragAttemptContentToAnotherTagTextPart(
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>
    ): Boolean {
        return theyDoNotBelongToSameTagTextPart(draggedContentTagIdDuo, droppedOnContentTagIdDuo)
    }

    private fun tryToDragContentToAnotherTextPart(
        req: DragContentRequest,
        currentOrder: List<Tuple2<ContentID, TagID>>,
        currentOrderOnDistinctGroupView: ArrayList<Tuple2<ContentID, TagID>>,
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>,
        rollbackMoment: Long
    ): String {
        val content = contentService.findEntity(draggedContentTagIdDuo.a)!!
        val updatedTagsOfContent = ArrayList(content.tags)
        updatedTagsOfContent.remove(draggedContentTagIdDuo.b)
        if (!updatedTagsOfContent.contains(droppedOnContentTagIdDuo.b)) {
            updatedTagsOfContent.add(droppedOnContentTagIdDuo.b)
        }
        val updatedContent = content.copy(
            tags = updatedTagsOfContent,
            lastModifiedAt = now()
        )
        dataHolder.updateContent(updatedContent, rollbackMoment)

        val updatedDraggedContentIdTagDuo =  Tuple2(
            draggedContentTagIdDuo.a,
            droppedOnContentTagIdDuo.b
        )

        val updatedCurrentOrder = currentOrder
            .filter { it != updatedDraggedContentIdTagDuo } //if we dragged content to a tagTextPart which already contains content (and we enable to see because of "Distinct"GroupView), we delete old same ContentIdTagId duos from viewOrder. Otherwise, duplicate contents are being started to seen in GroupView
            .map {
            if (it == draggedContentTagIdDuo) updatedDraggedContentIdTagDuo else it
        }

        val draggedToUpside: Boolean =
            draggedToUpside(currentOrderOnDistinctGroupView, draggedContentTagIdDuo, droppedOnContentTagIdDuo)

        val contentTagDuosToDrag: List<Tuple2<ContentID, TagID>> =
            updatedCurrentOrder.filter { (a, _) -> a == req.idOfDraggedContent }!!

        val orderStatusAfterDuosToDragAreRemoved = updatedCurrentOrder.filterNot { contentTagDuosToDrag.contains(it) }

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
}
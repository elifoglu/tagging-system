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
open class GroupViewDragService(
    private val contentService: ContentService,
    private val tagService: TagService,
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

    @ExperimentalStdlibApi
    fun dragContent(req: DragContentRequest, rollbackMoment: Long): String {
        val currentOrder = dataHolder.getAllData().contentViewOrder
        val tagTextPartsForGroupView: List<TagTextResponse.TagTextPart> =
            contentService.getTagTextPartsForGroupView(tagService.findEntity(req.idOfActiveTagPage)!!)
        tagTextPartsForGroupView

        val draggedContentIdTagIdDuo = Tuple2(req.idOfDraggedContent, req.idOfTagGroupThatDraggedContentBelong)
        val toDropOnContentIdTagIdDuo = Tuple2(req.idOfContentToDropOn, req.idOfTagGroupToDropOn)

        if (isADragAttemptContentToAnotherTagTextPart(draggedContentIdTagIdDuo, toDropOnContentIdTagIdDuo)) {
            return tryToDragContentToAnotherTextPart(
                req,
                currentOrder,
                tagTextPartsForGroupView,
                draggedContentIdTagIdDuo,
                toDropOnContentIdTagIdDuo,
                rollbackMoment
            )
        }

        val draggedToUpside: Boolean =
            draggedToUpside(currentOrder, draggedContentIdTagIdDuo, toDropOnContentIdTagIdDuo)

        if (oneAfterAnotherAndNotMoveable(
                currentOrder,
                draggedContentIdTagIdDuo,
                toDropOnContentIdTagIdDuo,
                req.dropToFrontOrBack
            )
        ) {
            return "it-will-stay-on-same-place-so-no-need-to-drag"
        }

        val contentTagDuoToDrag: Tuple2<ContentID, TagID> =
            currentOrder.find { it == draggedContentIdTagIdDuo }!!

        val orderStatusAfterDuoToDragIsRemoved = currentOrder.filterNot { it == contentTagDuoToDrag }

        val contentTagDuoToDropDraggedOn: Tuple2<ContentID, TagID> =
            if (draggedToUpside) {
                orderStatusAfterDuoToDragIsRemoved.find { (a, _) -> a == req.idOfContentToDropOn }!!
            } else {
                orderStatusAfterDuoToDragIsRemoved.findLast { (a, _) -> a == req.idOfContentToDropOn }!!
            }

        val index = orderStatusAfterDuoToDragIsRemoved
            .indexOf(contentTagDuoToDropDraggedOn)

        val leftSideOfTheList = orderStatusAfterDuoToDragIsRemoved.take(index)
        val rightSideOfTheList = orderStatusAfterDuoToDragIsRemoved.drop(index + 1)
        val newContentViewOrder: ArrayList<Tuple2<ContentID, TagID>> = ArrayList()
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
        currentOrderOnDistinctGroupView: List<Tuple2<ContentID, TagID>>,
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>
    ): Boolean {
        return currentOrderOnDistinctGroupView.indexOf(draggedContentTagIdDuo) > currentOrderOnDistinctGroupView.indexOf(
            droppedOnContentTagIdDuo
        )
    }

    private fun oneAfterAnotherAndNotMoveable(
        currentOrder: List<Tuple2<ContentID, TagID>>,
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedToFrontOrBack: String
    ): Boolean {
        if (theyDoNotBelongToSameTagTextPart(draggedContentTagIdDuo, droppedOnContentTagIdDuo)) {
            return false
        }

        return (currentOrder.indexOf(draggedContentTagIdDuo) - currentOrder.indexOf(
            droppedOnContentTagIdDuo
        ) == 1 && droppedToFrontOrBack == "back") ||
                (currentOrder.indexOf(droppedOnContentTagIdDuo) - currentOrder.indexOf(
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
        tagTextPartsForDistinctGroupView: List<TagTextResponse.TagTextPart>,
        draggedContentTagIdDuo: Tuple2<ContentID, TagID>,
        droppedOnContentTagIdDuo: Tuple2<ContentID, TagID>,
        rollbackMoment: Long
    ): String {
        val foundTagTextPartOfContentToDropOn =
            tagTextPartsForDistinctGroupView.find { it.tag.tagId == droppedOnContentTagIdDuo.b }!!
        if (foundTagTextPartOfContentToDropOn.contents.filter { it.contentId == draggedContentTagIdDuo.a }
                .isNotEmpty()) {
            return "cannot-drag-to-a-text-part-if-it-already-contains-content"
        }
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

        val updatedDraggedContentIdTagDuo = Tuple2(
            draggedContentTagIdDuo.a,
            droppedOnContentTagIdDuo.b
        )

        val updatedCurrentOrder = currentOrder
            .map {
                if (it == draggedContentTagIdDuo) updatedDraggedContentIdTagDuo else it
            }

        val draggedToUpside: Boolean =
            draggedToUpside(currentOrder, draggedContentTagIdDuo, droppedOnContentTagIdDuo)

        val contentTagDuoToDrag: Tuple2<ContentID, TagID> =
            updatedCurrentOrder.find { it == updatedDraggedContentIdTagDuo }!!

        val orderStatusAfterDuoToDragIsRemoved = currentOrder.filterNot { it == contentTagDuoToDrag }


        val contentTagDuoToDropDraggedOn: Tuple2<ContentID, TagID> =
            if (draggedToUpside) {
                orderStatusAfterDuoToDragIsRemoved.find { it == droppedOnContentTagIdDuo }!!
            } else {
                orderStatusAfterDuoToDragIsRemoved.findLast { it == droppedOnContentTagIdDuo }!!
            }

        val index = orderStatusAfterDuoToDragIsRemoved
            .indexOf(contentTagDuoToDropDraggedOn)

        val leftSideOfTheList = orderStatusAfterDuoToDragIsRemoved.take(index)
        val rightSideOfTheList = orderStatusAfterDuoToDragIsRemoved.drop(index + 1)
        val newContentViewOrder: ArrayList<Tuple2<ContentID, TagID>> = ArrayList()
        newContentViewOrder.addAll(leftSideOfTheList)

        if (req.dropToFrontOrBack == "front") {
            newContentViewOrder.add(updatedDraggedContentIdTagDuo)
            newContentViewOrder.add(contentTagDuoToDropDraggedOn)
        } else {
            newContentViewOrder.add(contentTagDuoToDropDraggedOn)
            newContentViewOrder.add(updatedDraggedContentIdTagDuo)
        }

        newContentViewOrder.addAll(rightSideOfTheList)

        dataHolder.updateContentViewOrderWith(newContentViewOrder, rollbackMoment)

        return "ok"
    }
}


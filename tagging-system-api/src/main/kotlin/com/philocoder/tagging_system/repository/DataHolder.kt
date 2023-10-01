package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.AllData
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.util.DateUtils.now
import org.springframework.stereotype.Component
import java.util.*

@Component
open class DataHolder {

    private var data: AllData? = null

    fun addAllData(allData: AllData) {
        data = allData
    }

    fun getAllData() = data!!

    fun addContent(content: Content, rollbackMoment: Long?) {
        val newList: ArrayList<Content> = ArrayList()
        newList.addAll(data!!.contents)
        newList.add(content)
        data = data!!.copy(contents = newList)

        if (rollbackMoment == null) {
            return
        }

        addAtomicOperation(
            Companion.AtomicRollbackOperationOnData.RollbackContentCreation(
                rollbackMoment,
                content.contentId
            )
        )
    }

    fun updateContent(content: Content, rollbackMoment: Long?) {
        val previousVersionOfContent: Content = data!!.contents.find { it.contentId == content.contentId }!!

        val updatedContentList = data!!.contents
            .map { if (it.contentId == content.contentId) content else it }
        data = data!!.copy(contents = updatedContentList)

        if (rollbackMoment == null) {
            return
        }

        addAtomicOperation(
            Companion.AtomicRollbackOperationOnData.RollbackContentUpdate(
                rollbackMoment,
                previousVersionOfContent
            )
        )
    }

    fun deleteContent(id: String, rollbackMoment: Long?) {
        val previousVersionOfContent: Content = data!!.contents.find { it.contentId == id }!!

        val updatedContents = data!!.contents.map {
            if (it.contentId != id) it else it.copy(
                isDeleted = true,
                lastModifiedAt = now(),
            )
        }
        data = data!!.copy(contents = updatedContents)

        if (rollbackMoment == null) {
            return
        }

        addAtomicOperation(
            Companion.AtomicRollbackOperationOnData.RollbackContentDeletion(
                rollbackMoment,
                previousVersionOfContent
            )
        )

    }

    fun addTag(tag: Tag, rollbackMoment: Long?) {
        val newList: ArrayList<Tag> = ArrayList()
        newList.addAll(data!!.tags)
        newList.add(tag)
        data = data!!.copy(tags = newList)

        if (rollbackMoment == null) {
            return
        }

        addAtomicOperation(
            Companion.AtomicRollbackOperationOnData.RollbackTagCreation(
                rollbackMoment,
                tag.tagId
            )
        )

    }

    fun updateTag(tag: Tag, rollbackMoment: Long?) {
        val previousVersionOfTag: Tag = data!!.tags.find { it.tagId == tag.tagId }!!

        val updatedTagList = data!!.tags
            .map { if (it.tagId == tag.tagId) tag else it }
        data = data!!.copy(tags = updatedTagList)

        if (rollbackMoment == null) {
            return
        }

        addAtomicOperation(
            Companion.AtomicRollbackOperationOnData.RollbackTagUpdate(
                rollbackMoment,
                previousVersionOfTag
            )
        )
    }

    fun deleteTag(id: String, rollbackMoment: Long?) {
        val previousVersionOfTag: Tag = data!!.tags.find { it.tagId == id }!!

        val updatedTags = data!!.tags.map {
            if (it.tagId != id) it else it.copy(
                isDeleted = true,
                lastModifiedAt = now(),
            )
        }
        data = data!!.copy(tags = updatedTags)

        if (rollbackMoment == null) {
            return
        }

        addAtomicOperation(
            Companion.AtomicRollbackOperationOnData.RollbackTagDeletion(
                rollbackMoment,
                previousVersionOfTag
            )
        )
    }

    /* UNDO MODULE - START */
    private val undoLimit: Int = 10

    private var undoStack: ArrayList<AtomicRollbackOperationOnData> = ArrayList()

    private fun groupedUndoStack(): ArrayList<OperationGroup> {
        val distinctRollbackIds = undoStack.map { it.rollbackId }.distinct()
        val operationDataList = HashMap<Long, ArrayList<AtomicRollbackOperationOnData>>()
        distinctRollbackIds.forEach {
            operationDataList[it] = ArrayList()
        }
        undoStack.reversed().forEach { //reversed() is critical to make the whole rollback in proper "descending" order
            operationDataList[it.rollbackId]!!.add(it)
        }
        val sortedOperationDataListToUse = ArrayList<OperationGroup>()
        operationDataList.keys.sortedWith { a, b -> (a - b).toInt() }
            .forEach { sortedOperationDataListToUse.add(operationDataList[it]!!) }
        return sortedOperationDataListToUse
    }

    private fun popLatestOperationGroupToRollback(): OperationGroup {
        val latestOperationGroup: OperationGroup = groupedUndoStack().last()
        val rollBackIdToRemove =
            latestOperationGroup[0].rollbackId // since all rollbackIds are the same in an OperationGroup, i simple do get(0) to reach rollbackId

        undoStack = ArrayList(undoStack.filter { it.rollbackId != rollBackIdToRemove })

        return latestOperationGroup
    }

    private fun addAtomicOperation(operationData: AtomicRollbackOperationOnData) {
        undoStack.add(operationData)

        if (groupedUndoStack().size > undoLimit) {
            undoStack = ArrayList(groupedUndoStack().drop(1).flatten())
        }
    }

    fun isRollbackStackEmpty() = groupedUndoStack().isEmpty()

    fun undo() {
        if (groupedUndoStack().isEmpty()) {
            return
        }

        popLatestOperationGroupToRollback()
            .forEach {
                when (it) {
                    is AtomicRollbackOperationOnData.RollbackContentCreation -> deleteContent(
                        it.contentIdToDelete,
                        null
                    )
                    is AtomicRollbackOperationOnData.RollbackContentUpdate -> updateContent(
                        it.oldVersionOfContent,
                        null
                    )
                    is AtomicRollbackOperationOnData.RollbackContentDeletion -> updateContent(
                        it.oldVersionOfContent,
                        null
                    )
                    is AtomicRollbackOperationOnData.RollbackTagCreation -> deleteTag(it.tagIdToDelete, null)
                    is AtomicRollbackOperationOnData.RollbackTagUpdate -> updateTag(it.oldVersionOfTag, null)
                    is AtomicRollbackOperationOnData.RollbackTagDeletion -> updateTag(
                        it.oldVersionOfTag,
                        null
                    )
                }
            }
    }

    companion object {

        sealed class AtomicRollbackOperationOnData(val rollbackId: Long) {
            class RollbackContentCreation(rollbackId: Long, val contentIdToDelete: String) :
                AtomicRollbackOperationOnData(rollbackId)

            class RollbackContentUpdate(rollbackId: Long, val oldVersionOfContent: Content) :
                AtomicRollbackOperationOnData(rollbackId)

            class RollbackContentDeletion(rollbackId: Long, val oldVersionOfContent: Content) :
                AtomicRollbackOperationOnData(rollbackId)

            class RollbackTagCreation(rollbackId: Long, val tagIdToDelete: String) :
                AtomicRollbackOperationOnData(rollbackId)

            class RollbackTagUpdate(rollbackId: Long, val oldVersionOfTag: Tag) :
                AtomicRollbackOperationOnData(rollbackId)

            class RollbackTagDeletion(rollbackId: Long, val oldVersionOfTag: Tag) :
                AtomicRollbackOperationOnData(rollbackId)
        }
    }

    /* UNDO MODULE - END */
}

typealias OperationGroup = List<DataHolder.Companion.AtomicRollbackOperationOnData>

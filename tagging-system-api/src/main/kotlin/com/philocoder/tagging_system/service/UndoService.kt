package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Component

@Component
open class UndoService(
    private val dataHolder: DataHolder
) {

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

    fun addAtomicOperation(operationData: AtomicRollbackOperationOnData) {
        undoStack.add(operationData)

        //bu kısımda sadece, groupedUndoStack()'teki toplam grup sayısını hesaplayıp, 5'i geçtiyse en eski rollbackId'li atomik operasyon'ları uçuracak
        if (groupedUndoStack().size > 5) {
            undoStack = ArrayList(groupedUndoStack().drop(1).flatten())
        }
    }

    fun undo() {
        if (groupedUndoStack().isEmpty()) {
            return
        }

        popLatestOperationGroupToRollback()
            .forEach {
                when (it) {
                    is AtomicRollbackOperationOnData.RollbackContentCreation -> dataHolder.deleteContent(
                        it.contentIdToDelete,
                        null
                    )
                    is AtomicRollbackOperationOnData.RollbackContentUpdate -> dataHolder.updateContent(
                        it.oldVersionOfContent,
                        null
                    )
                    is AtomicRollbackOperationOnData.RollbackContentDeletion -> dataHolder.updateContent(
                        it.oldVersionOfContent,
                        null
                    )
                    is AtomicRollbackOperationOnData.RollbackTagCreation -> dataHolder.deleteTag(it.tagIdToDelete, null)
                    is AtomicRollbackOperationOnData.RollbackTagUpdate -> dataHolder.updateTag(it.oldVersionOfTag, null)
                    is AtomicRollbackOperationOnData.RollbackTagDeletion -> dataHolder.updateTag(
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

}

typealias OperationGroup = List<UndoService.Companion.AtomicRollbackOperationOnData>

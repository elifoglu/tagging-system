package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.repository.ContentRepository
import com.philocoder.tagging_system.repository.DataHolder
import com.philocoder.tagging_system.repository.TagRepository
import org.springframework.stereotype.Component

@Component
open class UndoService(
    private val contentRepository: ContentRepository,
    private val tagRepository: TagRepository,
    private val dataHolder: DataHolder
) {

    private var undoStack: ArrayList<OperationData> = ArrayList()

    fun addNewOperation(operationData: OperationData) {
        undoStack.add(operationData)
        if (undoStack.size > 5) {
            undoStack = ArrayList(undoStack.drop(1))
        }
    }

    fun undo() {
        if (undoStack.isEmpty()) {
            return
        }

        undoStack.last().forEach {
            when (it) {
                is AtomicOperationOnData.OperationOnContent -> dataHolder.updateContent(it.oldOne)
                is AtomicOperationOnData.OperationOnTag -> dataHolder.updateTag(it.oldOne)
            }
        }
        undoStack = ArrayList(undoStack.dropLast(1))
    }

    companion object {

        sealed class AtomicOperationOnData {
            class OperationOnContent(val oldOne: Content) : AtomicOperationOnData()
            class OperationOnTag(val oldOne: Tag) : AtomicOperationOnData()
        }
    }

}

typealias OperationData = List<UndoService.Companion.AtomicOperationOnData>

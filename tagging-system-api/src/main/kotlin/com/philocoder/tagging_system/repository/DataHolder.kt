package com.philocoder.tagging_system.repository

import com.philocoder.tagging_system.model.AllData
import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag
import com.philocoder.tagging_system.service.UndoService
import com.philocoder.tagging_system.util.DateUtils.now
import org.springframework.stereotype.Component
import java.util.*

@Component
open class DataHolder(
    private val undoService: UndoService
) {

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

        if(rollbackMoment == null) {
            return
        }

        undoService.addAtomicOperation(
            UndoService.Companion.AtomicRollbackOperationOnData.RollbackContentCreation(
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

        if(rollbackMoment == null) {
            return
        }

        undoService.addAtomicOperation(
            UndoService.Companion.AtomicRollbackOperationOnData.RollbackContentUpdate(
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

        if(rollbackMoment == null) {
            return
        }

        undoService.addAtomicOperation(
            UndoService.Companion.AtomicRollbackOperationOnData.RollbackContentDeletion(
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

        if(rollbackMoment == null) {
            return
        }

        undoService.addAtomicOperation(
            UndoService.Companion.AtomicRollbackOperationOnData.RollbackTagCreation(
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

        if(rollbackMoment == null) {
            return
        }

        undoService.addAtomicOperation(
            UndoService.Companion.AtomicRollbackOperationOnData.RollbackTagUpdate(
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

        if(rollbackMoment == null) {
            return
        }

        undoService.addAtomicOperation(
            UndoService.Companion.AtomicRollbackOperationOnData.RollbackTagDeletion(
                rollbackMoment,
                previousVersionOfTag
            )
        )
    }
}
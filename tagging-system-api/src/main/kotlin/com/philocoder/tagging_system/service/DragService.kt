package com.philocoder.tagging_system.service

import com.philocoder.tagging_system.model.request.DragContentRequest
import com.philocoder.tagging_system.repository.DataHolder
import org.springframework.stereotype.Repository

@Repository
open class DragService(
    private val tagService: TagService,
    private val dataHolder: DataHolder
) {


    fun dragContent(req: DragContentRequest): String {
        return "ok"
    }
}



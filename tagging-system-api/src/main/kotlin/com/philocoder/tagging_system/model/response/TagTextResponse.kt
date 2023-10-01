package com.philocoder.tagging_system.model.response

import java.util.*

data class TagTextResponse(
    val textPartsForLineView: List<TagTextPart>,
    val textPartsForGroupView: List<TagTextPart>,
    val textPartsForDistinctGroupView: List<TagTextPart>
) {

    data class TagTextPart(val tag: TagResponse, val contents: List<ContentResponse>)

    companion object {
        val empty = TagTextResponse(Collections.emptyList(), Collections.emptyList(), Collections.emptyList())
    }
}
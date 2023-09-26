package com.philocoder.tagging_system.model.response

data class TagTextResponse(
    val textParts: List<TagTextPart>
) {

    data class TagTextPart(val tag: TagResponse, val contents: List<ContentResponse>)
}
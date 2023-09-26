package com.philocoder.tagging_system.model.response

import java.util.*

data class ContentsResponse(
    val contents: List<ContentResponse>,
    val condensedContentText: String
) {

    companion object {
        val empty =
            ContentsResponse(Collections.emptyList(), "")
    }
}
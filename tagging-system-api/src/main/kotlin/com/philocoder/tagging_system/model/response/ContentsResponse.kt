package com.philocoder.tagging_system.model.response

import java.util.*

data class ContentsResponse(
    val totalPageCount: Int,
    val contents: List<ContentResponse>
) {

    companion object {
        val empty =
            ContentsResponse(0, Collections.emptyList())
    }
}
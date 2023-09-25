package com.philocoder.tagging_system.model.response

import java.util.*

data class SearchContentResponse(
    val contents: List<ContentResponse>
) {

    companion object {
        val empty =
            SearchContentResponse(Collections.emptyList())
    }
}
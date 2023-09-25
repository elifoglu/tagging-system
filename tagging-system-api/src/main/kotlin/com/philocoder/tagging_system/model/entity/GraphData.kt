package com.philocoder.tagging_system.model.entity

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import java.util.*

data class GraphData(
    val titlesToShow: List<String>,
    val contentIds: List<ContentID>,
    val connections: List<Tuple2<Int, Int>>
) {
    companion object {
        val empty = GraphData(Collections.emptyList(), Collections.emptyList(), Collections.emptyList())
    }
}
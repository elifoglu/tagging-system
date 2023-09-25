package com.philocoder.tagging_system.model

import com.philocoder.tagging_system.model.entity.*

data class AllData(
    val contents: List<Content>,
    val tags: List<Tag>,
    val homeTagId: String,
    val wholeGraphData: GraphData,
    val graphDataOfContents: Map<ContentID, GraphData>
)
package com.philocoder.tagging_system.model

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.entity.*

data class AllData(
    val contents: List<Content>,
    val tags: List<Tag>,
    val contentViewOrder: List<Tuple2<ContentID, TagID>>,
    val homeTagId: String
)
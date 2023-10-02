package com.philocoder.tagging_system.model.request

import arrow.core.Tuple2
import com.philocoder.tagging_system.model.ContentID
import com.philocoder.tagging_system.model.TagID
import com.philocoder.tagging_system.model.entity.Content

data class GenerateDataRequest(
    val contents: List<Content>,
    val tags: List<TagWithoutChildTags>,
    val contentViewOrder: List<Tuple2<ContentID, TagID>>,
    val homeTagId: String
)
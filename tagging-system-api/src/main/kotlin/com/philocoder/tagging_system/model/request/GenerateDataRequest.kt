package com.philocoder.tagging_system.model.request

import com.philocoder.tagging_system.model.entity.Content

data class GenerateDataRequest(
    val contents: List<Content>,
    val tags: List<TagWithoutChildTags>,
    val homeTagId: String
)
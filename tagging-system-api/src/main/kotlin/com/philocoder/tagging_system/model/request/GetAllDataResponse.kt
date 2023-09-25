package com.philocoder.tagging_system.model.request

import com.philocoder.tagging_system.model.entity.Content
import com.philocoder.tagging_system.model.entity.Tag

data class GetAllDataResponse(
    val contents: List<Content>,
    val tags: List<Tag>
)
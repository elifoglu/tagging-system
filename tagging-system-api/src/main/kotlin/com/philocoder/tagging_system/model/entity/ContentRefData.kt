package com.philocoder.tagging_system.model.entity

import com.philocoder.tagging_system.model.ContentID

data class ContentRefData(
    val first: ContentID,
    val second: ContentID,
    val type: String
)
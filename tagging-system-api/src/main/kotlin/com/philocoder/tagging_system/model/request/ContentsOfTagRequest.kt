package com.philocoder.tagging_system.model.request

data class ContentsOfTagRequest(
    val tagId: String,
    val page: Int = 1,
    val size: Int = 10
)
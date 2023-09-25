package com.philocoder.tagging_system.model.request

data class CreateTagRequest(
    val tagId: String,
    val name: String
)
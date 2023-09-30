package com.philocoder.tagging_system.model.request

data class CreateTagRequest(
    val name: String,
    val description: String,
    val parentTags: List<String>
)
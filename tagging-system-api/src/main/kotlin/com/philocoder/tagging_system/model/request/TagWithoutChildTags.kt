package com.philocoder.tagging_system.model.request

data class TagWithoutChildTags(
    val tagId: String,
    val name: String,
    val parentTags: List<String>,
    val description: String,
    val createdAt: Long,
    val lastModifiedAt: Long,
    val isDeleted: Boolean
)
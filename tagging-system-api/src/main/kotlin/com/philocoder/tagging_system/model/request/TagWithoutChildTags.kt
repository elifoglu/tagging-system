package com.philocoder.tagging_system.model.request

data class TagWithoutChildTags(
    val tagId: String,
    val name: String,
    val parentTags: List<String>,
    val infoContentId: Int?,
    val createdAt: Long,
    val lastModifiedAt: Long,
    val isDeleted: Boolean
)
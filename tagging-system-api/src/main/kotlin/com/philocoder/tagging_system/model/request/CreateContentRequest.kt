package com.philocoder.tagging_system.model.request

data class CreateContentRequest(
    val id: String,
    override val title: String?,
    override val text: String,
    override val tags: String
): ContentRequest
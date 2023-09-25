package com.philocoder.tagging_system.model.request

data class UpdateContentRequest(
    val id: Int?,
    override val title: String?,
    override val text: String,
    override val tags: String
) : ContentRequest
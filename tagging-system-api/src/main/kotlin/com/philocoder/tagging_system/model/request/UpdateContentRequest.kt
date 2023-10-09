package com.philocoder.tagging_system.model.request

data class UpdateContentRequest(
    override val title: String?,
    override val text: String,
    override val tags: List<String>,
    override val asADoc: String
) : ContentRequest
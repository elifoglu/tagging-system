package com.philocoder.tagging_system.model.request

data class CreateContentRequest(
    override val title: String?,
    override val text: String,
    override val tags: List<String>,
    override val asADoc: String,
    val existingContentContentIdToAddFrontOrBackOfIt: String?,
    val existingContentTagIdToAddFrontOrBackOfIt: String?,
    val frontOrBack: String?
): ContentRequest